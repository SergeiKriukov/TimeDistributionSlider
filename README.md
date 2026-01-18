# TimeDistributionSlider

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-lightgrey.svg)](https://developer.apple.com/swift/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Интерактивный SwiftUI компонент для визуального распределения времени между несколькими элементами с возможностью перетаскивания разделителей.

## Описание

`TimeDistributionSlider` — это настраиваемый компонент SwiftUI, который позволяет пользователям визуально распределять общее время между несколькими элементами (клиентами, задачами, проектами и т.д.) путем перетаскивания разделителей. Компонент автоматически отображает пропорции в виде цветных сегментов и показывает детальную информацию о времени, выделенном каждому элементу.

<img width="730" height="778" alt="image" src="https://github.com/user-attachments/assets/4f7ef855-493b-4ccc-ad89-4805bf6ee4d1" />


## Возможности

- 🎨 **Визуальное представление** — цветные сегменты для каждого элемента
- 🖱️ **Интерактивное перетаскивание** — изменение пропорций путем перетаскивания разделителей
- 📊 **Автоматическая легенда** — отображение времени для каждого элемента
- ⚙️ **Настраиваемые параметры**:
  - Минимальная доля на элемент
  - Режим проталкивания соседних разделителей
  - Общая длительность времени
- 🔄 **Гибкая архитектура** — поддержка кастомных типов через протокол `TimeDistributable`
- 📱 **Кроссплатформенность** — поддержка iOS, macOS, watchOS и tvOS

## Требования

- iOS 15.0+ / macOS 12.0+ / watchOS 8.0+ / tvOS 15.0+
- Swift 5.9+
- Xcode 15.0+

## Установка

### Swift Package Manager

Добавьте зависимость в ваш `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/SergeiKriukov/TimeDistributionSlider.git", from: "1.0.0")
]
```

Или добавьте через Xcode:
1. File → Add Packages...
2. Введите URL: `https://github.com/SergeiKriukov/TimeDistributionSlider`
3. Выберите версию и нажмите Add Package

## Быстрый старт

### Базовое использование

```swift
import SwiftUI
import TimeDistributionSlider

struct ContentView: View {
    @State private var clients: [Client] = [
        Client(name: "Клиент 1"),
        Client(name: "Клиент 2"),
        Client(name: "Клиент 3")
    ]
    @State private var proportions: [UUID: Double] = [:]
    
    var body: some View {
        TimeDistributionSlider(
            totalDuration: 8 * 3600, // 8 часов
            clients: clients,
            proportions: $proportions,
            minShare: 0.05, // минимум 5% на клиента
            enablePush: true // разрешить проталкивание разделителей
        )
        .onAppear {
            // Инициализация равномерного распределения
            let equalShare = 1.0 / Double(clients.count)
            proportions = Dictionary(uniqueKeysWithValues: 
                clients.map { ($0.id, equalShare) }
            )
        }
    }
}
```

### Использование с кастомными типами

```swift
import SwiftUI
import TimeDistributionSlider

// Определите свой тип, соответствующий протоколу TimeDistributable
struct Project: TimeDistributable {
    let id: UUID
    let name: String
    let priority: Int
    
    init(id: UUID = UUID(), name: String, priority: Int = 1) {
        self.id = id
        self.name = name
        self.priority = priority
    }
}

struct ProjectView: View {
    @State private var projects: [Project] = [
        Project(name: "Проект A", priority: 1),
        Project(name: "Проект B", priority: 2),
        Project(name: "Проект C", priority: 3)
    ]
    @State private var proportions: [UUID: Double] = [:]
    
    var body: some View {
        TimeDistributionSlider(
            totalDuration: 40 * 3600, // 40 часов рабочей недели
            clients: projects,
            proportions: $proportions,
            minShare: 0.1, // минимум 10% на проект
            enablePush: true
        )
    }
}
```

## API

### `TimeDistributionSlider`

Основной компонент для распределения времени.

#### Параметры инициализации

- `totalDuration: TimeInterval` — общая длительность времени для распределения (в секундах)
- `clients: [Item]` — массив элементов для распределения (должны соответствовать протоколу `TimeDistributable`)
- `proportions: Binding<[UUID: Double]>` — binding на словарь пропорций (ключ — UUID элемента, значение — доля от 0.0 до 1.0)
- `minShare: Double` — минимальная доля на элемент (по умолчанию `0.05`, т.е. 5%)
- `enablePush: Bool` — разрешить проталкивание соседних разделителей при достижении минимальной доли (по умолчанию `true`)

### `TimeDistributable`

Протокол для элементов, которые могут быть распределены по времени.

```swift
public protocol TimeDistributable: Identifiable {
    var id: UUID { get }
    var name: String { get }
}
```

### `Client`

Базовая реализация `TimeDistributable` для быстрого старта.

```swift
public struct Client: TimeDistributable {
    public let id: UUID
    public let name: String
    
    public init(id: UUID = UUID(), name: String)
}
```

## Примеры использования

### Распределение рабочего времени между задачами

```swift
struct TaskDistributionView: View {
    @State private var tasks: [Client] = [
        Client(name: "Разработка"),
        Client(name: "Тестирование"),
        Client(name: "Документация")
    ]
    @State private var proportions: [UUID: Double] = [:]
    
    var body: some View {
        VStack {
            TimeDistributionSlider(
                totalDuration: 8 * 3600, // рабочий день
                clients: tasks,
                proportions: $proportions,
                minShare: 0.1,
                enablePush: true
            )
            
            // Дополнительная информация
            ForEach(tasks) { task in
                let share = proportions[task.id] ?? 0
                let hours = (8 * 3600 * share) / 3600
                Text("\(task.name): \(String(format: "%.1f", hours)) часов")
            }
        }
    }
}
```

### Распределение бюджета времени на неделю

```swift
struct WeeklyPlanView: View {
    @State private var activities: [Client] = [
        Client(name: "Работа"),
        Client(name: "Спорт"),
        Client(name: "Отдых"),
        Client(name: "Семья")
    ]
    @State private var proportions: [UUID: Double] = [:]
    
    var body: some View {
        TimeDistributionSlider(
            totalDuration: 7 * 24 * 3600, // неделя в секундах
            clients: activities,
            proportions: $proportions,
            minShare: 0.05,
            enablePush: true
        )
    }
}
```

## Особенности реализации

- **Проталкивание разделителей**: При включенном режиме `enablePush` компонент автоматически проталкивает соседние разделители, когда один из сегментов достигает минимальной доли, обеспечивая плавное и интуитивное взаимодействие.

- **Нормализация пропорций**: Компонент автоматически нормализует пропорции, гарантируя, что их сумма всегда равна 1.0.

- **Визуальная обратная связь**: Каждый элемент отображается своим цветом, а разделители имеют тени для лучшей видимости.

## Лицензия

Этот проект распространяется под лицензией MIT. См. файл [LICENSE](LICENSE) для подробностей.

## Автор

**Sergey**

- GitHub: [@SergeiKriukov](https://github.com/SergeiKriukov)

## Вклад

Вклады приветствуются! Пожалуйста, создайте issue или pull request для обсуждения изменений.

## Поддержка

Если у вас возникли вопросы или проблемы, пожалуйста, создайте [issue](https://github.com/SergeiKriukov/TimeDistributionSlider/issues) на GitHub.
