# Инструкция по использованию библиотеки

## Локальное использование в Xcode проекте

### Вариант 1: Добавить локальный пакет

1. Откройте ваш Xcode проект
2. File → Add Packages...
3. Нажмите "Add Local..."
4. Выберите папку `TimeDistributionSlider` (где находится `Package.swift`)
5. Нажмите "Add Package"
6. В вашем проекте добавьте зависимость на `TimeDistributionSlider`

### Вариант 2: Через File → Add Files to Project

1. Откройте ваш Xcode проект
2. File → Add Files to "YourProject"...
3. Выберите папку `TimeDistributionSlider`
4. Убедитесь, что выбран "Create groups" и "Add to targets: YourTarget"
5. В настройках проекта (Build Phases) добавьте `TimeDistributionSlider` в зависимости

## Публикация на GitHub

1. Создайте новый репозиторий на GitHub
2. Инициализируйте git в папке проекта:
   ```bash
   cd TimeDistributionSlider
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/yourusername/TimeDistributionSlider.git
   git push -u origin main
   ```
3. Создайте тег для версии:
   ```bash
   git tag 1.0.0
   git push origin 1.0.0
   ```

## Использование из GitHub

После публикации, другие могут использовать библиотеку так:

1. File → Add Packages...
2. Введите URL: `https://github.com/yourusername/TimeDistributionSlider.git`
3. Выберите версию или ветку
4. Нажмите "Add Package"

## Использование в коде

```swift
import SwiftUI
import TimeDistributionSlider

struct MyView: View {
    @State private var clients: [Client] = [
        Client(name: "Клиент 1"),
        Client(name: "Клиент 2")
    ]
    @State private var proportions: [UUID: Double] = [:]
    
    var body: some View {
        TimeDistributionSlider(
            totalDuration: 8 * 3600,
            clients: clients,
            proportions: $proportions
        )
    }
}
```
