---
name: build-and-verify
description: "Собрать Qt-клиент MoexGRPCClient (JOM в build/ или Ninja вне репозитория) и убедиться, что сборка чистая: без ошибок и без предупреждений в src/."
whenToUse: "Любая правка файлов src/ или CMakeLists.txt, а также проверка перед коммитом."
---

# build-and-verify

Собрать клиент и подтвердить, что правки не сломали сборку. Полные правила репозитория —
в `AGENTS.md` (он может ссылаться на `SKILLS.md` с кодстайлом и порядком проверки).

## Вариант A — build-каталог Qt Creator (JOM)

```bat
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
set "PATH=C:\Qt2\Tools\QtCreator\bin\jom;C:\Qt2\Tools\CMake_64\bin;%PATH%"
cmake --build build\Desktop_Qt_6_11_1_MSVC2022_64bit_Debug --config Debug
```

## Вариант B — отдельный каталог вне репозитория

Ничего не пишет в репозиторий (кроме обновления `protobuf_generated/`, если собирать цель
`ALL`; поэтому цель указывается явно).

```bat
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
set "PATH=C:\Qt2\Tools\Ninja;C:\Qt2\Tools\CMake_64\bin;%PATH%"
cmake -S . -B %TEMP%\moex_build -G Ninja -DCMAKE_BUILD_TYPE=Debug ^
      -DQt6_DIR=C:/Qt2/6.11.1/msvc2022_64/lib/cmake/Qt6 ^
      -DCMAKE_PREFIX_PATH=C:/Qt2/6.11.1/msvc2022_64
cmake --build %TEMP%\moex_build --target appMoexGRPCClient --parallel
```

## Критерий готовности

- нет `error C…` / `error LNK…`;
- в файлах `src/` нет `warning C…` — действуют `/W4 /external:anglebrackets /external:W0`,
  поэтому шум из Qt/gRPC/protobuf не оправдание;
- `protobuf_generated/` не изменился больше, чем ожидалось (это генерируемый каталог).

## Грабли

| Симптом | Причина и что делать |
|---|---|
| `LNK1168: не удается открыть appMoexGRPCClient.exe` | запущен старый экземпляр — закрыть приложение и повторить |
| `C1083: ../../../protobuf_generated/protobuf.grpc.pb.h` | вернулся старый относительный путь; правильный include — `"protobuf.grpc.pb.h"` |
| `C1083: libpq-fe.h` | не найден PostgreSQL: `POSTGRESQL_ROOT_DIR` в `CMakeLists.txt` (`C:/Program Files/PostgreSQL/17`) |
| CMake не находит Qt | не передан `Qt6_DIR`/`CMAKE_PREFIX_PATH` (`C:/Qt2/6.11.1/msvc2022_64`) |
| Ошибка `ninja: command not found` | `C:\Qt2\Tools\Ninja` не в `PATH` |

## Дальше

Если правка касалась потока или БД — выполните `client-e2e-check`. Если управления
памятью — `leak-check-crt`.
