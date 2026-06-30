---
name: hh-clicker
description: >
  Управление автокликером hh.ru (форк hh-applicant-tool, менторская программа IT Птица).
  Используй, когда нужно установить, настроить или запустить автоотклики на hh.ru: установка с нуля,
  авторизация, AI-письма (бесплатный Groq или OpenRouter), массовая рассылка откликов с фильтрами,
  ответы работодателям в чатах, поднятие резюме, анализ отказов. Все команды — из корня проекта
  через venv: `.venv/bin/python -m hh_applicant_tool <команда>`.
---

# hh-clicker — плейбук управления автокликером hh.ru

Это пошаговый плейбук для AI-агента. Полная человеческая версия — в `GUIDE.md` (читай её при сомнениях, особенно §15 «На что обращать внимание»). Изменения по датам — `CHANGELOG.md`.

## 🥇 ЗОЛОТОЕ ПРАВИЛО (нарушать нельзя)

**Перед ЛЮБОЙ массовой рассылкой — `--dry-run`.** Реальные отклики уходят живым работодателям и не отзываются. Сначала покажи пользователю, что улетит (письма + кого отфильтровало), и только после явного «ок» убирай `--dry-run`.

## Запуск команд

Всегда из корня проекта, через локальный venv:
```bash
.venv/bin/python -m hh_applicant_tool <команда> [аргументы]
```

---

## Шаг 1 — Установка (один раз)

```bash
python3 -m venv .venv
.venv/bin/pip install -e '.[playwright,pillow]'
.venv/bin/python -m hh_applicant_tool install      # Chromium для авторизации/капчи
```
Требования: Python 3.11+, Git.

## Шаг 2 — Авторизация

```bash
.venv/bin/python -m hh_applicant_tool auth          # введёт email + код из SMS/почты
.venv/bin/python -m hh_applicant_tool whoami        # проверить, кто залогинен
```
Токен живёт ~2 недели и обновляется сам (`refresh-token`). Если `refresh_token` истёк — повторить `auth`.

## Шаг 3 — Сопроводительное письмо

Базовое письмо — в `letter.txt` (корень проекта). Прикладывается к каждому отклику.
- Не завязывай на названия компаний (письмо одно на всех).
- **Не вставляй ссылки** — спам-фильтр hh может бросить в теневой бан.

## Шаг 4 — (опц.) Настроить AI для писем и ответов

AI нужен для: генерации письма под вакансию (`apply-vacancies --ai`) и ответов в чатах (`reply-employers --ai`). Одна секция конфига — `openai_cover_letter`. Провайдер на выбор:

**Бесплатный Groq** (рекомендуется, если не готовы платить) — `console.groq.com/keys`, ключ `gsk_...`:
```bash
.venv/bin/python -m hh_applicant_tool config -s openai_cover_letter.base_url https://api.groq.com/openai/v1/chat/completions
.venv/bin/python -m hh_applicant_tool config -s openai_cover_letter.model llama-3.3-70b-versatile
.venv/bin/python -m hh_applicant_tool config -s openai_cover_letter.api_key gsk_ВАШ_КЛЮЧ
.venv/bin/python -m hh_applicant_tool config -s openai_cover_letter.temperature 0.5
```

**OpenRouter** — `openrouter.ai/settings/keys`, ключ `sk-or-v1-...`, base_url `https://openrouter.ai/api/v1/chat/completions`, бесплатная модель `qwen/qwen3-next-80b-a3b-instruct:free`.

⚠️ **Ключи — только в конфиг локально.** Никогда не коммить, не вставлять в чат/скриншоты. Засветил — отзови и создай новый. Бесплатные модели в пик отдают `429` — для надёжной рассылки бери дешёвую платную (OpenRouter ~$10, письмо = доли цента).

## Шаг 5 — Рассылка откликов

Базовый вид:
```bash
.venv/bin/python -m hh_applicant_tool apply-vacancies \
  -L letter.txt -f \
  --search '(NAME:(frontend OR react OR typescript OR "next.js")) AND NOT NAME:(fullstack OR backend OR QA)' \
  --experience between1And3 \
  --excluded-filter 'golang|\bgo\b|laravel|symfony|\bphp\b|wordpress|1с|bitrix|битрикс' \
  --apply-delay-min 40 --apply-delay-max 180 \
  --dry-run
```

Ключевые параметры:
| Параметр | Описание |
|---|---|
| `-L letter.txt` | файл сопроводительного |
| `-f` | всегда прикладывать письмо |
| `--search` | поиск по **названию** (язык hh: AND/OR/NOT, `NAME:(...)`) |
| `--experience` | `noExperience` / `between1And3` / `between3And6` / `moreThan6` |
| `--area` | регион (1 = Москва, 2 = СПб; без него — все) |
| `--excluded-filter` | regex по названию **и описанию** (отсев чужого стека) |
| `--apply-delay-min/max` | случайная пауза между откликами (антибот) |
| `--dry-run` | проверка без реальных откликов |
| `--ai` | генерировать письмо под каждую вакансию (см. ниже) |

С AI-письмом под вакансию (промпт — `cover_letter_prompt.txt`):
```bash
.venv/bin/python -m hh_applicant_tool apply-vacancies --ai -f \
  --system-prompt "$(cat cover_letter_prompt.txt)" \
  --message-prompt "Данные вакансии и резюме ниже. Напиши письмо строго по правилам из системного промпта." \
  --search '...'
```

## Шаг 6 — Ответы работодателям

```bash
.venv/bin/python -m hh_applicant_tool reply-employers --ai
```
Отвечает **только там, где последнее сообщение от работодателя**. Анкеты (зарплата/график/тестовое) помечает и оставляет на ручную обработку. **Проверяй ответы** — это живые люди; важные чаты веди без `--ai`.

## Шаг 7 — Поднятие резюме

```bash
.venv/bin/python -m hh_applicant_tool update-resumes   # как кнопка «Обновить дату»
.venv/bin/python -m hh_applicant_tool list-resumes      # ID резюме
```

## Типичный ежедневный сценарий

```bash
.venv/bin/python -m hh_applicant_tool refresh-token
.venv/bin/python -m hh_applicant_tool update-resumes
.venv/bin/python -m hh_applicant_tool apply-vacancies -L letter.txt -f --search '...' --experience between1And3 --excluded-filter '...' --apply-delay-min 40 --apply-delay-max 180
.venv/bin/python -m hh_applicant_tool reply-employers --ai
```

---

## 🔑 Принцип фильтра (частая ошибка)

- `--search` фильтрует **только по названию**; `--excluded-filter` — по названию **и описанию**.
- Исключай только **однозначный чужой стек** (`golang`, `php`, `laravel`, `1с`…).
- **НЕ исключай `vue`/`angular`** словом: вакансии «React **или** Vue **или** Angular» тебе подходят, а слово-фильтр их выкинет. Тонкие случаи различает только `--ai-filter heavy` (читает описание + резюме).
- Regex-приёмы: `\bgo\b` ловит «Go», но не «Good»; регистр не важен.
- Ревью чёрного списка (не выкинуло ли хорошее):
```bash
.venv/bin/python -m hh_applicant_tool query "SELECT name, employer_name, matched FROM skipped_vacancies WHERE reason='excluded_filter' ORDER BY created_at DESC LIMIT 30"
```

## ⚠️ Грабли (из §15 GUIDE)

- **Лимит 200 откликов/сутки** на аккаунт. Не шли залпом — паузы + заходы по крону (дефолтный `crontab` шлёт 8:00–21:00).
- **Несколько аккаунтов с одного IP = баны.** Каждому аккаунту — свой прокси (лучше мобильный). Домашний IP безопаснее серверного.
- С `--excluded-filter`/`--ai`/`--ai-filter` рассылка медленная — догружается полное описание каждой вакансии. Долгое «🚀 Начинаю рассылку…» = не зависание (добавь `-vv` для прогресса).
- `--max-responses` не работает (баг) — ограничивай `--per-page`/`--total-pages`.
- Слабые AI-модели **врут факты** в письмах — режим «адаптация `letter.txt`» лучше, чем «с нуля»; перед рассылкой `--dry-run` и прочти пару писем.
- Ключи/`config.json`/`cookies.txt`/`data` живут **вне репозитория** — не переноси в git.

## Конфиг и несколько профилей

```bash
.venv/bin/python -m hh_applicant_tool config -p          # путь до конфига
.venv/bin/python -m hh_applicant_tool config -e          # открыть в редакторе
.venv/bin/python -m hh_applicant_tool --profile-id second auth   # второй аккаунт
```
macOS-путь конфига: `~/Library/Application Support/hh-applicant-tool/config.json`.

## Анализ отказов (докрутка резюме)

```bash
.venv/bin/python analyze_rejections.py [--profile-id <id>]
```
- **Быстрый отказ (минуты)** = автофильтр/ATS → помогут ключевые слова в резюме.
- **Медленный (часы/дни)** = смотрел человек → твики резюме почти не помогут.
- Добавляй в резюме **только реально знакомое**; алиасы писать оба написания («WebSocket» и «WebSockets», «Material UI» и «MUI»). Навыки-теги — лимит 30, лишнее → в «О себе».
