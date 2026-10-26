# Caelestia: команды и горячие клавиши

Снимок основной конфигурации от **26 августа 2026 г.**; голосовая диктовка добавлена **26 октября 2026 г.**

- Caelestia Shell: `2.3.0` (`caelestia-shell-git 2.3.0.r11.g1d0e5a5-1`)
- Caelestia CLI: `1.1.2-1`
- Quickshell: `0.3.1-1.1`
- Конфигурация хоткеев: `~/.config/hypr/hyprland/keybinds.lua`
- Значения хоткеев: `~/.config/hypr/variables.lua`
- Дополнительные пользовательские хоткеи: `~/.config/caelestia/hypr-user.lua`
- Пользовательские переопределения: отсутствуют (`~/.config/caelestia/hypr-vars.lua` пуст)

Обозначения: `Super` — клавиша Windows; `ЛКМ/ПКМ` — левая/правая кнопка мыши; `колесо ↓/↑` — прокрутка вниз/вверх.

## Горячие клавиши

### Интерфейс и сеанс

| Клавиши | Действие |
|---|---|
| `Super` (нажать и отпустить левую) | Открыть лаунчер |
| `Ctrl + Alt + Delete` | Меню сеанса |
| `Super + N` | Боковая панель |
| `Ctrl + Alt + C` | Очистить уведомления |
| `Super + K` | Показать все панели |
| `Super + L` | Заблокировать экран |
| `Super + Alt + L` | Восстановить/перезапустить экран блокировки |
| `Super + Shift + L` | Сон (`suspend-then-hibernate`) |
| `Ctrl + Super + Shift + R` | Остановить Caelestia Shell |
| `Ctrl + Super + Alt + R` | Перезапустить Caelestia Shell |

### Запуск приложений

| Клавиши | Действие / команда |
|---|---|
| `Super + T` | Терминал — `foot` |
| `Super + W` | Браузер — `zen-browser` |
| `Super + C` | Редактор — `codium` |
| `Super + E` | Файловый менеджер — `thunar` |
| `Ctrl + Alt + V` | Настройки звука — `pwvucontrol` |

### Рабочие столы

| Клавиши | Действие |
|---|---|
| `Super + 1…0` | Перейти на рабочий стол 1…10 |
| `Super + Alt + 1…0` | Переместить окно на рабочий стол 1…10 |
| `Ctrl + Super + 1…0` | Перейти в группу рабочих столов 1…10 |
| `Ctrl + Super + Alt + 1…0` | Переместить окно в группу 1…10 |
| `Super + колесо ↓` / `Ctrl + Super + →` / `Super + Page Down` | Следующий рабочий стол |
| `Super + колесо ↑` / `Ctrl + Super + ←` / `Super + Page Up` | Предыдущий рабочий стол |
| `Ctrl + Super + колесо ↓/↑` | Следующая/предыдущая группа рабочих столов |
| `Super + Alt + колесо ↓` / `Super + Alt + Page Down` / `Ctrl + Super + Shift + →` | Переместить окно на следующий стол |
| `Super + Alt + колесо ↑` / `Super + Alt + Page Up` / `Ctrl + Super + Shift + ←` | Переместить окно на предыдущий стол |
| `Super + Alt + S` / `Ctrl + Super + Shift + ↑` | Переместить окно в специальный стол |
| `Ctrl + Super + Shift + ↓` | Вернуть окно из специального стола |

### Специальные рабочие столы

| Клавиши | Действие |
|---|---|
| `Super + S` | Специальный стол |
| `Ctrl + Shift + Escape` | Системный монитор |
| `Super + M` | Музыка |
| `Super + D` | Коммуникации |
| `Super + R` | Задачи / Todo |

### Окна и группы

| Клавиши | Действие |
|---|---|
| `Super + ←/→/↑/↓` | Перевести фокус в направлении |
| `Super + Shift + ←/→/↑/↓` | Переместить окно в направлении |
| `Alt + Tab` / `Shift + Alt + Tab` | Следующее/предыдущее окно |
| `Ctrl + Alt + Tab` / `Ctrl + Shift + Alt + Tab` | Следующее/предыдущее окно в группе |
| `Super + ,` | Создать/разобрать группу окон |
| `Super + Shift + ,` | Заблокировать активную группу |
| `Super + U` | Убрать окно из группы |
| `Super + -` / `Super + Alt + ←` | Уменьшить ширину окна |
| `Super + =` / `Super + Alt + →` | Увеличить ширину окна |
| `Super + Shift + -` / `Super + Alt + ↑` | Уменьшить высоту окна |
| `Super + Shift + =` / `Super + Alt + ↓` | Увеличить высоту окна |
| `Super + Z` или `Super + ЛКМ` | Перетаскивать окно |
| `Super + X` или `Super + ПКМ` | Изменять размер окна |
| `Ctrl + Super + \\` | Центрировать окно |
| `Ctrl + Super + Alt + \\` | Нормализовать размер (55×70%) и центрировать |
| `Super + Alt + \\` | Режим «картинка в картинке» |
| `Super + P` | Закрепить окно поверх рабочих столов |
| `Super + F` | Полноэкранный режим |
| `Super + Alt + F` | Полноэкранный режим с рамкой |
| `Super + Alt + Space` / `Super + Shift + W` | Плавающее/плиточное окно |
| `Super + Q` | Закрыть окно |

### Снимки, запись и утилиты

| Клавиши | Действие / команда |
|---|---|
| `Print` | Снимок экрана — `caelestia screenshot` |
| `Super + Shift + S` | Снимок области с заморозкой экрана |
| `Super + Shift + Alt + S` | Снимок выбранной области |
| `Ctrl + Alt + R` | Запись экрана |
| `Super + Alt + R` | Запись экрана со звуком |
| `Super + Shift + Alt + R` | Запись выбранной области |
| `Super + Shift + C` | Пипетка цвета; копирует цвет (`hyprpicker -a`) |
| `Super + V` | История буфера обмена |
| `Super + Alt + V` | Удаление из истории буфера |
| `Ctrl + Shift + Alt + V` | Вставить последний элемент буфера |
| `Super + .` | Выбор эмодзи/символа |
| `Super + Shift + D` | Голосовая диктовка: начать запись / завершить и скопировать текст |
| `Super + Shift + Escape` | Отменить диктовку без копирования текста |

### Голосовая диктовка

1. Нажмите и отпустите `Super + Shift + D`: запись включится и появится уведомление. Удерживать клавиши не нужно; уведомление остаётся на экране во время записи.
2. Говорите по-русски. Для диктовки используется **встроенный микрофон ноутбука**; музыка продолжает играть в наушниках. Микрофон Bluetooth-гарнитуры не открывается, чтобы не переключать её аудиопрофиль и не прерывать воспроизведение.
3. Нажмите и отпустите `Super + Shift + D` ещё раз: микрофон перестанет записывать, уведомление сменится на распознавание. Затем появится готовый текст, который также окажется в буфере обмена.
4. Вставьте текст через `Ctrl + V` (в терминале — `Ctrl + Shift + V`).

`Super + Shift + Escape` отменяет запись или распознавание. Максимальная длина одной записи — 120 секунд; затем запись завершается автоматически. Диктовка заменяет содержимое буфера обмена; текст также может попасть в его историю Caelestia.

Используется [Voxtype 1.1.1](https://github.com/peteonrails/voxtype) с многоязычной моделью Whisper `large-v3-turbo-q5_0` и ускорением Vulkan на NVIDIA. Распознавание работает локально, без отправки аудио в интернет. Модель загружается по необходимости, после распознавания процесс с моделью завершается и освобождает видеопамять. Это отдельная интеграция с Hyprland, запускаемая вместе с пользовательским сеансом.

- Программа: `~/.local/bin/voxtype`
- Настройки, включая язык (`language = "ru"`; для определения языка — `"auto"`): `~/.config/voxtype/config.toml`
- Выбор встроенного микрофона только для службы диктовки: `~/.config/systemd/user/voxtype.service.d/microphone.conf` (`PULSE_SOURCE`). Системный микрофон по умолчанию для остальных приложений не меняется. В настройках Voxtype явно отключены пауза и приглушение музыки (`pause_media = false`, `duck_media = false`).
- Модель (~574 МБ): `~/.local/share/voxtype/models/ggml-large-v3-turbo-q5_0.bin`
- Состояние: `~/.local/bin/voxtype status`
- Журнал: `journalctl --user -u voxtype -n 50 --no-pager`
- Перезапуск после изменения настроек: `systemctl --user restart voxtype`
- Отключить автозапуск: `systemctl --user disable --now voxtype`

В локальном `~/.config/quickshell/caelestia/services/NotifData.qml` исправлено отображение уведомлений: нулевой тайм-аут сохраняет индикатор записи до остановки, а обновлённое уведомление появляется повторно. После замены локальной конфигурации Shell эти исправления нужно сохранить.

### Медиа, звук и яркость

| Клавиши | Действие |
|---|---|
| `Ctrl + Super + Space` / `Play` / `Pause` | Воспроизведение/пауза |
| `Ctrl + Super + =` / `Next` | Следующий трек |
| `Ctrl + Super + -` / `Previous` | Предыдущий трек |
| `Ctrl + Super + Backspace` / `Stop` | Остановить воспроизведение |
| `Super + Shift + M` / `Mute` | Выключить/включить звук |
| `Mic Mute` | Выключить/включить микрофон |
| `Volume Up` / `Volume Down` | Громкость ±10%, максимум 100% |
| `Brightness Up` / `Brightness Down` | Яркость экрана вверх/вниз |

### Диагностика

| Клавиши | Действие |
|---|---|
| `Super + Alt + F12` | Показать тестовое уведомление Caelestia Shell |

## Команды Caelestia CLI

Общий формат: `caelestia [--help] [--version] <команда> [параметры]`.

| Команда | Назначение / основные параметры |
|---|---|
| `caelestia --help` | Общая справка |
| `caelestia --version` | Версии CLI, Shell, Quickshell и dotfiles |
| `caelestia shell` | Запустить Shell |
| `caelestia shell -d` | Запустить Shell в фоне |
| `caelestia shell -s` | Показать доступные IPC-команды (требует запущенный Shell) |
| `caelestia shell -l` | Показать журнал Shell |
| `caelestia shell -k` | Остановить Shell |
| `caelestia shell --log-rules RULES` | Запустить с правилами журналирования |
| `caelestia shell MESSAGE…` | Отправить IPC-сообщение Shell |
| `caelestia toggle WORKSPACE` | Переключить специальный рабочий стол |
| `caelestia screenshot` | Снимок всего экрана |
| `caelestia screenshot -r [REGION]` | Снимок области; область можно передать явно |
| `caelestia screenshot -f` | Заморозить экран при выборе области |
| `caelestia record` | Начать/завершить запись экрана |
| `caelestia record -r [REGION]` | Записывать выбранную или указанную область |
| `caelestia record -s` | Записывать звук |
| `caelestia record -p` | Пауза/продолжение записи |
| `caelestia record -c` | Скопировать путь к записи в буфер |
| `caelestia clipboard` | Открыть историю буфера обмена |
| `caelestia clipboard -d` | Выбрать и удалить элемент истории |
| `caelestia emoji -p` | Открыть выбор эмодзи/символов |
| `caelestia emoji -f` | Загрузить данные эмодзи/символов |
| `caelestia wallpaper -p [PATH]` | Показать цветовую схему обоев |
| `caelestia wallpaper -r [DIR]` | Выбрать случайные обои |
| `caelestia wallpaper -f FILE` | Установить указанный файл обоев |
| `caelestia wallpaper -n` | Не фильтровать изображения по размеру |
| `caelestia wallpaper -t N` | Минимальный размер картинки в процентах от крупнейшего монитора |
| `caelestia wallpaper -N` | Не менять режим схемы автоматически по цвету обоев |
| `caelestia resizer -d` | Запустить демон изменения размеров окон |
| `caelestia resizer PATTERN MATCH WIDTH HEIGHT ACTIONS` | Изменить окно; MATCH: `titleContains`, `titleExact`, `titleRegex`, `initialTitle`; ACTIONS: `float,center,pip` |
| `caelestia scheme list` | Список доступных схем |
| `caelestia scheme list -n/-f/-m/-v` | Список имён / вариантов вкуса / режимов / вариантов Material |
| `caelestia scheme get` | Текущая схема целиком |
| `caelestia scheme get -n/-f/-m/-v` | Текущее имя / вкус / режим / вариант Material |
| `caelestia scheme set -r` | Случайная схема |
| `caelestia scheme set -n NAME` | Выбрать имя схемы |
| `caelestia scheme set -f FLAVOUR` | Выбрать flavour схемы |
| `caelestia scheme set -m dark|light` | Тёмный/светлый режим |
| `caelestia scheme set -v VARIANT` | Вариант Material: `tonalspot`, `vibrant`, `expressive`, `fidelity`, `fruitsalad`, `monochrome`, `neutral`, `rainbow`, `content` |
| `caelestia scheme set --notify …` | Показывать уведомление при ошибке смены схемы |
| `caelestia install` | Установить/перенастроить dotfiles |
| `caelestia install --aur-helper paru|yay` | Выбрать AUR-помощник |
| `caelestia install --enable-components LIST` | Включить компоненты через список с запятыми |
| `caelestia install --disable-components LIST` | Отключить компоненты через список с запятыми |
| `caelestia install --noconfirm` | Использовать ответы по умолчанию |
| `caelestia update` | Обновить Caelestia dotfiles |
| `caelestia update --aur-helper paru|yay` | Выбрать AUR-помощник |
| `caelestia update --noconfirm` | Обновление без вопросов |

Параметры можно сочетать, например: `caelestia record -r -s -c` или `caelestia screenshot -r -f`.

## Где менять хоткеи

Пользовательские изменения следует вносить в `~/.config/caelestia/hypr-vars.lua`, чтобы обновления штатной конфигурации не затёрли их. Формат:

```lua
return {
    kbTerminal = "SUPER + RETURN",
    kbBrowser = { "SUPER + W", "SUPER + B" },
}
```

После изменения перезагрузите конфигурацию Hyprland или перезапустите сеанс.

Новые хоткеи, которых нет среди штатных переменных, добавляются в `~/.config/caelestia/hypr-user.lua`. Например, там настроены сочетания для голосовой диктовки.
