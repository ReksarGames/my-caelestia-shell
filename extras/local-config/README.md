# Пользовательская конфигурация

Снимок настроек действующей установки от 26 октября 2026 г. Эти файлы находятся вне каталога Quickshell и сохраняются здесь вместе с исходниками Shell.

- `caelestia/`: настройки Shell, переопределения и дополнительные хоткеи Hyprland.
- `voxtype/config.toml`: локальное распознавание русского через Whisper; `Super + Shift + D` включает/выключает запись, `Super + Shift + Escape` отменяет её.
- `systemd/user/voxtype.service`: автозапуск Voxtype в графическом сеансе.
- `systemd/user/voxtype.service.d/microphone.conf`: встроенный микрофон только для диктовки, без смены системного микрофона и Bluetooth-профиля наушников.

Voxtype 1.1.1, бинарный файл `~/.local/bin/voxtype` и модель `~/.local/share/voxtype/models/ggml-large-v3-turbo-q5_0.bin` (~574 МБ) устанавливаются отдельно и в Git не включены. Источники: [Voxtype](https://github.com/peteonrails/voxtype/releases/tag/v1.1.1), [модель Whisper](https://huggingface.co/ggerganov/whisper.cpp/blob/main/ggml-large-v3-turbo-q5_0.bin). Нужны рабочие PipeWire-Pulse, ALSA PulseAudio plugin, `wl-copy`, `notify-send` и Vulkan.

Это снимок конкретного ноутбука: в путях модели и службы используется `/home/kirill`, а имя встроенного микрофона — `alsa_input.pci-0000_05_00.6.analog-stereo`. На другом компьютере эти значения нужно заменить.

Для восстановления настроек на текущем ноутбуке после установки зависимостей и модели, из корня репозитория:

```sh
cp -a extras/local-config/caelestia extras/local-config/voxtype ~/.config/
cp -a extras/local-config/systemd/user/. ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now voxtype
systemctl --user restart voxtype
hyprctl reload
```

Caelestia dotfiles должны загружать `~/.config/caelestia/hypr-user.lua` и `hypr-vars.lua`. После изменения QML перезапустите Shell: в этом снимке автоматическая перезагрузка файлов отключена.

Проверено на действующей установке: запись идёт со встроенного микрофона; состояние MPRIS-проигрывателя, потока воспроизведения и Bluetooth-профиля сохраняется; индикатор виден дольше штатного тайм-аута и при повторном запуске диктовки. Сборка C++ плагина из исходников при сохранении снимка не выполнялась.
