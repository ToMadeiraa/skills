---
name: client-e2e-check
description: "Прогнать клиент по полному пути gRPC-сервер -> DataClient -> PostgreSQL и сверить число записанных строк; применяется после изменений в grpcclient.* и databaseworker.*."
whenToUse: "Изменения в потоке, батчах, SQL или конфигурации БД; проверка перед коммитом; жалобы «сервер не отвечает / данные не пишутся»."
---

# client-e2e-check

Проверить сквозной сценарий и отличить проблемы клиента от проблем сервера/БД.

## 1. Проверить, что сервер вообще отдаёт данные

Прямой gRPC-запрос на `132.243.18.52:50051` (метод `MyGRPCServer.DataService/StreamData`,
пустой `DataRequest`, h2c):

```bash
printf '\x00\x00\x00\x00\x00' > /tmp/req.bin
curl --http2-prior-knowledge -sS --max-time 10 -D /tmp/hdr.txt -o /tmp/resp.bin \
  -H 'content-type: application/grpc' -H 'te: trailers' \
  --data-binary @/tmp/req.bin \
  "http://132.243.18.52:50051/MyGRPCServer.DataService/StreamData"
grep -E 'HTTP/2|grpc-status|content-type' /tmp/hdr.txt; ls -l /tmp/resp.bin
```

- `HTTP/2 200` + `grpc-status: 0` + непустое тело → сервер и его БД живы;
- `grpc-status` с ошибкой → проблема на стороне сервера (не в клиенте);
- `curl exit 7/28` или отказ → порт не опубликован/фаервол (диагностика сервера).

## 2. Запустить клиент

GUI-подсистема без консоли — **обязательно** перенаправление вывода:

```bat
set "PATH=C:\Program Files\PostgreSQL\17\bin;C:\tesseract\vcpkg\installed\x64-windows\debug\bin;C:\tesseract\vcpkg\installed\x64-windows\bin;C:\Qt2\6.11.1\msvc2022_64\bin;%PATH%"
set "TICKERS_FILE=%CD%\tickers.txt"
start /wait appMoexGRPCClient.exe > out.txt 2>&1
```

Адрес сервера — `DEFAULT_SERVER_TARGET` в `src/main.cpp`, параметры запроса — `secid`
(индекс в `tickers.txt`) и `tradeno` (нижняя граница).

## 3. Что должно быть в выводе

```
connecting to db...
connected to DB!
loaded tickers: 38
Сервер: 132.243.18.52:50051
Запрос: secid=0 tradeno=0
получено 20000, отправлено в БД 20000
Поток завершён. Получено записей: N, отправлено в БД: M, ошибок записи: 0
```

## 4. Сверить БД

```bat
set PGPASSWORD=12345678
psql -h 127.0.0.1 -p 5432 -U postgres -d db_client ^
     -c "select count(*), max(tradeno) from gazp_client"
psql -h 127.0.0.1 -p 5432 -U postgres -d db_client ^
     -c "select tradeno, price, quantity, systime, buysell from gazp_client order by tradeno desc limit 3"
```

Ожидается: `M == N` (все полученные строки записаны), цены с копейками (`109.19`),
`buysell` = `0/1`, а повторный прогон **не меняет** `count(*)` (идемпотентность
`ON CONFLICT (TRADENO) DO NOTHING`).

## Диагностика по симптому

| Симптом | Что смотреть |
|---|---|
| `cannot connect to DB!` | PostgreSQL не запущен / нет базы `db_client` (создать: `createdb`) |
| `loaded tickers: 0` / сообщения нет | не найден `tickers.txt` — задать `TICKERS_FILE` |
| `secid … вне списка тикеров` | `secid` в `main.cpp` больше числа тикеров |
| `Поток завершён … ошибок записи: N>0` | смотреть `stderr`: ошибки SQL/соединения |
| `RPC завершился с ошибкой` | `status.error_message()`; сверить с шагом 1 |
| прогресса нет и процесс висит | сервер принял запрос, но его пул БД пуст (проверить `docker logs` сервера) |

## Ограничения

Прогон **пишет** строки в БД `db_client` (это нормальное поведение приложения).
Не запускайте на боевой базе; для проверки достаточно локального PostgreSQL.
