---
name: leak-check-crt
description: "Проверить Debug-сборку клиента на утечки памяти встроенным отчётом CRT: временная правка main.cpp, прогон с недостижимым сервером, подсчёт блоков, откат правки."
whenToUse: "Изменения во владении ресурсами (unique_ptr, libpq, gRPC reader/stub), после ревью кода на утечки, при росте памяти."
---

# leak-check-crt

Проверка утечек без сторонних инструментов: MSVC Debug CRT сам печатает отчёт при выходе.

## Порядок

1. **Временная правка `src/main.cpp`** (потом откатить):

```cpp
#include <crtdbg.h>
#include <QTimer>
...
int main(int argc, char *argv[])
{
    _CrtSetReportMode(_CRT_WARN, _CRTDBG_MODE_FILE);
    _CrtSetReportFile(_CRT_WARN, _CRTDBG_FILE_STDERR);
    _CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
    ...
```

2. **Чтобы приложение могло корректно выйти** (иначе отчёт не напечатается):
   - `DEFAULT_SERVER_TARGET` → недостижимый адрес (`127.0.0.1:59999`), чтобы
     `WaitForServer` не пустил поток и `main` дошёл до `exec()`;
   - перед `exec()`: `QTimer::singleShot(3000, &app, &QCoreApplication::quit);`

3. **Собрать и запустить** (Debug, вывод `stderr` в файл):

```bat
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
set "PATH=C:\Program Files\PostgreSQL\17\bin;C:\tesseract\vcpkg\installed\x64-windows\debug\bin;C:\tesseract\vcpkg\installed\x64-windows\bin;C:\Qt2\6.11.1\msvc2022_64\bin;%PATH%"
set "TICKERS_FILE=%CD%\tickers.txt"
appMoexGRPCClient.exe > out.txt 2> err.txt
```

4. **Считать отчёт** в `err.txt`: строки `normal block at 0x…, N bytes long` —
   количество блоков и сумма байт. Отдельно проверить, что в дампе нет `db_client`,
   `localhost`, `postgres` (это были бы блоки `DatabaseWorker`/`Config`).

5. **Откатить правки и проверить чистоту:**

```bat
git checkout -- src/main.cpp
git status --short
```

## Как трактовать результат

- Подавляющая часть блоков в отчёте — разовые глобальные аллокации Qt/gRPC,
  к коду проекта они не относятся.
- Ориентир для исправленного кода: **≈892 блока / 120 293 байта**; до исправления
  утечки `DatabaseWorker` было 904 / 120 957.
- Надёжнее метода: A/B — прогон «как есть» и прогон с временным `delete` владельца;
  разница в блоках/байтах и есть утечка (для этой правки было 14 блоков / 744 байта
  на один `DataClient`, плюс живое соединение libpq).

## Грабли

- Приложение — GUI-подсистема: без перенаправления вывода отчёт **не виден**.
- Если процесс убить (`Stop-Process`), отчёт не печатается вообще — нужен штатный выход.
- `_CRTDBG_*` работает только в Debug; в Release-сборке вызовы — no-op.
- Запущенный старый экземпляр ломает линковку (`LNK1168`) — закройте его перед сборкой.
