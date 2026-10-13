#!/bin/bash
echo "[$(date)] Running startup tasks..."

# echo "Current user: $(whoami)"
# echo "$CONFIG_DIR"

# Выполняем цепочку
/usr/local/bin/python -m hh_applicant_tool refresh-token
/usr/local/bin/python -m hh_applicant_tool update-resumes
# apply-vacancies здесь отключён: при старте он уходил БЕЗ letter.txt и без
# --excluded-filter, то есть дефолтным шаблонным письмом и без стоп-слов.
# Рассылка идёт по крону (crontab, 8:00-21:00) с -l /app/letter.txt -f.

echo "[$(date)] Startup tasks finished."
