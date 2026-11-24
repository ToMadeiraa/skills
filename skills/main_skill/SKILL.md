---
name: main-skill
description: "Точка входа для C++/Qt-работы: загружай этот скилл первым и выбирай по нему специализированный скилл. Ссылается на address-sanitizer, architecture, ci-cd-best-practices, codestyle, core-cpp, docker, grpc-expert, code-review, ui-ux-design, sql-postgresql с пояснением, когда каждый нужен."
---

# Main skill — точка входа

Этот скилл загружается первым для любой задачи в этом воркспейсе. Он не заменяет
специализированные скиллы, а выбирает 1–3 из них. Прямое указание пользователя важнее
любой строки таблицы.

## Как пользоваться

1. Определи тип задачи и выбери строки, у которых совпадает «Когда».
2. Загрузи выбранные скиллы по точному имени через инструмент `skill`. Если скилла нет в
   каталоге, прочитай файл по ссылке.
3. Перед ответом назови, какие скиллы загружены и почему.
4. Не загружай все строки сразу: это лишний контекст и противоречивые советы.

## Всегда действует

- Правила проекта (`SKILLS.md`, `AGENTS.md`) и `cpp-codestyle` важнее любого скилла.
- В проекте запрещены namespace, исключения и сущности уровня файла; переменные — `snake_case`.
- Если скилл противоречит правилам проекта, побеждают правила проекта, а не скилл.

## Маршрутизация

| Точное имя скилла | Файл | Когда использовать |
|---|---|---|
| `core-cpp` | [../core-cpp/SKILL.md](../core-cpp/SKILL.md) | Любая работа с C++ на уровне кода: написать, отрефакторить, отревьюить, определить стандарт. Не для системного дизайна. |
| `codestyle` | [../codestyle/SKILL.md](../codestyle/SKILL.md) | Нужен минимальный полный diff, YAGNI, lean-код; общий метод для любой задачи. Не заменяет `core-cpp`. |
| `architecture` | [../architecture/SKILL.md](../architecture/SKILL.md) | Системный дизайн: монолит/сервисы, границы, tradeoffs, ADR, runtime/deployment, риски, паттерны. Не для одной функции. |
| `code-review` | [../review/SKILL.md](../review/SKILL.md) | Ревью PR, ветки, коммита или незакоммиченных изменений. Подгружает `cpp-review` и `qt-review`. |
| `address-sanitizer` | [../address-sanitizer/SKILL.md](../address-sanitizer/SKILL.md) | Порча памяти, fuzzing, ASan/LSan на Linux/Clang. На Windows-Qt для утечек сначала `leak-check-crt`. |
| `sql-postgresql` | [../sql-postgresql/SKILL.md](../sql-postgresql/SKILL.md) | SQL и PostgreSQL: запросы, индексы, планы, JSONB, транзакции. Существующая схема важнее стиля. |
| `grpc-expert` | [../gRPC/SKILL.md](../gRPC/SKILL.md) | `.proto`, стриминг, каналы, дедлайны, статусы. Не менять уже работающий транспорт без просьбы. |
| `ci-cd-best-practices` | [../ci-cd/SKILL.md](../ci-cd/SKILL.md) | Пайплайны, деплой, IaC, тесты в CI. Не применять к C++-коду. |
| `docker` | [../docker/SKILL.md](../docker/SKILL.md) | Только если проект реально контейнеризуется. Qt-клиент — нет. |
| `ui-ux-design` | [../ui-ux-design/SKILL.md](../ui-ux-design/SKILL.md) | Только web UI/UX. Для Qt Widgets/QML не применять; там `code-review` с `qt-review`. |

## Проверка после изменений

Эти скиллы берутся из каталога по имени, без ссылок:

- `build-and-verify` — после правок `src/` или `CMakeLists.txt`;
- `client-e2e-check` — после изменений потока, батчей, SQL или конфигурации БД;
- `leak-check-crt` — после изменений владения памятью, на Windows.

## Частые ошибки

- Загрузить `architecture` для одной строки кода.
- Заменить `core-cpp` на `codestyle`: `codestyle` — метод, `core-cpp` — правила C++.
- Применить `docker`, `ui-ux-design` или `ci-cd` к Qt-клиенту без прямой просьбы.
- Загрузить все скиллы сразу.
