# Пользовательская конфигурация

Снимок настроек действующей установки от 1 ноября 2026 г. Эти файлы находятся вне каталога Quickshell и сохраняются здесь вместе с исходниками Shell.

- `caelestia/`: настройки Shell, переопределения и дополнительные хоткеи Hyprland.
- `hypr/hyprland/input.lua`: настройки ввода и `Alt + Shift`, переключающий все клавиатуры на один номер раскладки при нажатии второй клавиши. Требуется Hyprland 0.57+ с `hl.get_devices()`; внешние `jq` и `xargs` не нужны.
- `voxtype/`: локальное распознавание русского через Whisper. `Super + Shift + D` включает и останавливает запись, `Super + Shift + Escape` отменяет её.
- `systemd/user/voxtype.service`: автозапуск Voxtype в графическом сеансе.

Диктовка использует выбранный системный микрофон. Воспроизведение продолжается на прежней громкости во время записи.

Voxtype сохраняет завершённую запись в `$XDG_RUNTIME_DIR/voxtype/dictation-*.wav` перед распознаванием. При сбое или тайм-ауте Vulkan Whisper повторяет попытку на CPU. После получения текста WAV удаляется. Если текст получить не удалось, уведомление показывает путь к WAV, а файл хранится до завершения пользовательской сессии или перезагрузки. Для ручного распознавания такого файла можно использовать `voxtype transcribe /путь/к/записи.wav`; исходный файл после ручного запуска можно удалить.

Бинарный файл Voxtype 1.1.1 устанавливается в `~/.local/bin/voxtype`, модель — в `~/.local/share/voxtype/models/ggml-large-v3-turbo-q5_0.bin` (~574 МБ). Нужны Python 3, PipeWire-Pulse, ALSA PulseAudio plugin, `wl-copy`, `notify-send` и Vulkan для ускорения. Источники: [Voxtype](https://github.com/peteonrails/voxtype/releases/tag/v1.1.1), [модель Whisper](https://huggingface.co/ggerganov/whisper.cpp/blob/main/ggml-large-v3-turbo-q5_0.bin).

Это снимок конкретного ноутбука: в путях модели и службы используется `/home/kirill`. На другом компьютере эти пути нужно заменить.

Для восстановления настроек на текущем ноутбуке после установки зависимостей и модели, из корня репозитория:

Если была установлена предыдущая версия снимка с привязкой к встроенному микрофону, предварительно удалите `~/.config/systemd/user/voxtype.service.d/microphone.conf`. В текущей версии этот override не используется.

```sh
cp -a extras/local-config/caelestia extras/local-config/voxtype extras/local-config/hypr ~/.config/
cp -a extras/local-config/systemd/user/. ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now voxtype
systemctl --user restart voxtype
hyprctl reload
```

Caelestia dotfiles должны загружать `~/.config/caelestia/hypr-user.lua` и `hypr-vars.lua`. После изменения QML перезапустите Shell: в этом снимке автоматическая перезагрузка файлов отключена.

Проверка исправления раскладок в действующем Hyprland: `python3 tests/test_keyboard_layout.py` из корня репозитория. Проверка временно переключает EN/RU/UA, проверяет индикатор и синхронизацию устройств, затем восстанавливает исходный номер раскладки основной клавиатуры.

Проверка самого сочетания: `python3 tests/test_layout_shortcut.py`. Нужны `python-evdev` и доступ к `/dev/uinput`. Тест создаёт временную клавиатуру и посылает только Alt/Shift, проверяя четыре порядка нажатия/отпускания, затем освобождает модификаторы и восстанавливает номера раскладок. Во время теста не печатайте. До исправления проходили 10 из 20 переключений, после — 20 из 20.

Проверка обработки временных записей и повтора на CPU: `python3 tests/test_voxtype_transcribe.py`. Для Shell 2.5.0 нативные модули собраны с Qt 6.12 и установлены рядом с локальной оболочкой.

## Управление жестами

Страница «Система → Плагины → Управление жестами» включает и останавливает службу `gesture-caelestia.service`. Для установки службы запусти `sh install.sh` в отдельном проекте `~/Project/gesture-caelestia`. Любое приложение пользователя может управлять той же службой через команду `~/.local/bin/gesture-caelestia` с аргументом `start`, `stop` или `status`.
