//
//  TimeDistributionSlider.swift
//  TimeDistributionSlider
//
//  Created by Sergey on 15.01.2026.
//

import SwiftUI

// MARK: - Client Protocol
/// Протокол для элементов, которые могут быть распределены по времени
public protocol TimeDistributable: Identifiable {
    var id: UUID { get }
    var name: String { get }
}

// MARK: - Default Client Implementation
/// Базовая реализация клиента для распределения времени
public struct Client: TimeDistributable {
    public let id: UUID
    public let name: String
    
    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: - TimeDistributionSlider
/// Компонент для визуального распределения времени между несколькими элементами
/// 
/// Позволяет пользователю перетаскивать разделители для изменения пропорций времени,
/// выделенного каждому элементу.
///
/// ```swift
/// @State private var proportions: [UUID: Double] = [:]
/// 
/// TimeDistributionSlider(
///     totalDuration: 8 * 3600, // 8 часов
///     clients: clients,
///     proportions: $proportions,
///     minShare: 0.05, // минимум 5% на клиента
///     enablePush: true // разрешить проталкивание разделителей
/// )
/// ```
public struct TimeDistributionSlider<Item: TimeDistributable>: SwiftUI.View {
    /// Общая длительность времени для распределения
    public let totalDuration: TimeInterval
    
    /// Массив элементов для распределения
    public let clients: [Item]
    
    /// Binding на словарь пропорций (долей от 0.0 до 1.0) для каждого элемента
    @Binding public var proportions: [UUID: Double]
    
    /// Минимальная доля, которую должен получить каждый элемент (от 0.0 до 1.0)
    public let minShare: Double
    
    /// Разрешить ли проталкивание соседних разделителей при достижении минимальной доли
    public let enablePush: Bool
    
    @State private var activeSeparatorIndex: Int? = nil
    
    private let colors: [Color] = [.blue, .green, .orange, .purple, .mint, .red, .cyan, .pink]

    /// Инициализатор компонента
    /// - Parameters:
    ///   - totalDuration: Общая длительность времени для распределения
    ///   - clients: Массив элементов для распределения
    ///   - proportions: Binding на словарь пропорций (ключ - UUID элемента, значение - доля от 0.0 до 1.0)
    ///   - minShare: Минимальная доля на элемент (по умолчанию 0.05 = 5%)
    ///   - enablePush: Разрешить проталкивание разделителей (по умолчанию true)
    public init(
        totalDuration: TimeInterval,
        clients: [Item],
        proportions: Binding<[UUID: Double]>,
        minShare: Double = 0.05,
        enablePush: Bool = true
    ) {
        self.totalDuration = totalDuration
        self.clients = clients
        self._proportions = proportions
        self.minShare = minShare
        self.enablePush = enablePush
    }

    public var body: some SwiftUI.View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                let width = geometry.size.width
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.1))
                    
                    // Цветные сегменты (раскладываем последовательно)
                    HStack(spacing: 0) {
                        ForEach(0..<clients.count, id: \.self) { index in
                            let client = clients[index]
                            let share = proportions[client.id] ?? 0
                            let w = max(0, share * width)
                            
                            Rectangle()
                                .fill(colors[index % colors.count])
                                .frame(width: w)
                        }
                    }
                    .clipShape(Capsule())
                    
                    // Разделители
                    if clients.count > 1 {
                        ForEach(0..<clients.count - 1, id: \.self) { index in
                            let positionVal = prevShareSum(index: index + 1)
                            let x = positionVal * width
                            
                            Circle()
                                .fill(Color.white)
                                .shadow(radius: 2)
                                .frame(width: 20, height: 20)
                                .offset(x: x - 10)
                        }
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("slider"))
                        .onChanged { value in
                            if activeSeparatorIndex == nil {
                                activeSeparatorIndex = nearestSeparatorIndex(
                                    for: value.startLocation.x,
                                    width: width,
                                    maxDistance: 18
                                )
                            }
                            if let index = activeSeparatorIndex {
                                let newPos = value.location.x / width
                                updateProportions(separatorIndex: index, newPos: newPos)
                            }
                        }
                        .onEnded { _ in
                            activeSeparatorIndex = nil
                        }
                )
                .coordinateSpace(name: "slider")
            }
            .frame(height: 24)
            
            // Legend
            HStack(spacing: 8) {
                 ForEach(0..<clients.count, id: \.self) { index in
                     let client = clients[index]
                     let share = proportions[client.id] ?? 0
                     let time = totalDuration * share
                     
                     HStack(spacing: 4) {
                         Circle()
                            .fill(colors[index % colors.count])
                            .frame(width: 8, height: 8)
                         Text("\(client.name): \(formatDuration(time))")
                             .font(.caption)
                             .fixedSize()
                     }
                     .padding(4)
                     .background(Color.secondary.opacity(0.05))
                     .cornerRadius(4)
                 }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func prevShareSum(index: Int) -> Double {
        clients.prefix(index).reduce(0) { $0 + (proportions[$1.id] ?? 0) }
    }
    
    private func normalizedShares() -> [Double] {
        let raw = clients.map { proportions[$0.id] ?? 0 }
        let sum = raw.reduce(0, +)
        if sum <= 0 {
            return Array(repeating: 1.0 / Double(max(1, clients.count)), count: clients.count)
        }
        return raw.map { $0 / sum }
    }
    
    private func updateProportions(separatorIndex: Int, newPos: Double) {
        if enablePush {
            updateProportionsWithPush(separatorIndex: separatorIndex, newPos: newPos)
        } else {
            updateProportionsSimple(separatorIndex: separatorIndex, newPos: newPos)
        }
    }
    
    // Простое обновление без проталкивания (старая логика)
    private func updateProportionsSimple(separatorIndex: Int, newPos: Double) {
        let leftClient = clients[separatorIndex]
        let rightClient = clients[separatorIndex + 1]
        
        // Boundaries
        let startLeft = prevShareSum(index: separatorIndex)
        let endRight = prevShareSum(index: separatorIndex + 2)
        
        // Clamp (включая границы 0...1 на всякий случай)
        let clampedNewPos = min(max(newPos, max(0, startLeft + minShare)), min(1, endRight - minShare))
        
        let newShareLeft = clampedNewPos - startLeft
        let newShareRight = endRight - clampedNewPos
        
        proportions[leftClient.id] = newShareLeft
        proportions[rightClient.id] = newShareRight
    }
    
    // Обновление с проталкиванием соседних разделителей
    private func updateProportionsWithPush(separatorIndex: Int, newPos: Double) {
        let n = clients.count
        guard n >= 2 else { return }
        
        // Если minShare слишком большой (невозможная конфигурация) — не делаем ничего
        guard minShare * Double(n) <= 1 else { return }
        
        // Пересчитываем через границы (0...1), чтобы уметь "толкать" соседние разделители
        let shares = normalizedShares()
        var bounds = Array(repeating: 0.0, count: n + 1)
        bounds[0] = 0
        for i in 1..<n {
            bounds[i] = bounds[i - 1] + shares[i - 1]
        }
        bounds[n] = 1
        
        // Двигаем границу между [separatorIndex] и [separatorIndex + 1]
        let boundaryIndex = separatorIndex + 1
        
        // Ограничиваем новую позицию только общими границами (0...1)
        // Не используем консервативные глобальные пределы заранее - они слишком ограничивают
        var target = min(max(newPos, 0), 1)
        bounds[boundaryIndex] = target
        
        // Проталкиваем влево: гарантируем, что каждый сегмент >= minShare
        // Но делаем это итеративно, чтобы учесть все ограничения
        var changed = true
        while changed {
            changed = false
            
            // Проталкиваем влево
            if boundaryIndex > 0 {
                for i in stride(from: boundaryIndex, through: 1, by: -1) {
                    let segmentSize = bounds[i] - bounds[i - 1]
                    if segmentSize < minShare {
                        let newBoundary = bounds[i] - minShare
                        if bounds[i - 1] != newBoundary {
                            bounds[i - 1] = newBoundary
                            changed = true
                        }
                    }
                }
            }
            bounds[0] = 0
            
            // Проталкиваем вправо
            if boundaryIndex < n {
                for i in boundaryIndex..<n {
                    let segmentSize = bounds[i + 1] - bounds[i]
                    if segmentSize < minShare {
                        let newBoundary = bounds[i] + minShare
                        if bounds[i + 1] != newBoundary {
                            bounds[i + 1] = newBoundary
                            changed = true
                        }
                    }
                }
            }
            bounds[n] = 1
            
            // Если после проталкивания целевая граница сдвинулась слишком далеко,
            // корректируем её обратно, но с учётом ограничений
            if bounds[boundaryIndex] != target {
                // Пытаемся вернуть целевую позицию, но с учётом minShare
                let minPossible = boundaryIndex > 0 ? bounds[boundaryIndex - 1] + minShare : 0
                let maxPossible = boundaryIndex < n ? bounds[boundaryIndex + 1] - minShare : 1
                
                if target < minPossible {
                    target = minPossible
                    bounds[boundaryIndex] = target
                    changed = true
                } else if target > maxPossible {
                    target = maxPossible
                    bounds[boundaryIndex] = target
                    changed = true
                } else {
                    bounds[boundaryIndex] = target
                }
            }
        }
        
        // Переводим обратно в доли
        var newShares = (0..<n).map { bounds[$0 + 1] - bounds[$0] }
        
        // Чуть стабилизируем сумму (из-за double-ошибок)
        let sum = newShares.reduce(0, +)
        if abs(sum - 1.0) > 0.0001 && sum != 0 {
            let diff = 1 - sum
            newShares[n - 1] += diff
        }
        
        for (idx, client) in clients.enumerated() {
            proportions[client.id] = max(0, newShares[idx])
        }
    }
    
    private func nearestSeparatorIndex(for x: CGFloat, width: CGFloat, maxDistance: CGFloat) -> Int? {
        guard clients.count > 1, width > 0 else { return nil }
        
        var bestIndex: Int?
        var bestDistance = CGFloat.greatestFiniteMagnitude
        
        for index in 0..<(clients.count - 1) {
            let positionVal = prevShareSum(index: index + 1)
            let posX = CGFloat(positionVal) * width
            let distance = abs(x - posX)
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }
        
        if bestDistance <= maxDistance {
            return bestIndex
        }
        return nil
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        if hours > 0 {
            return String(format: "%dч %02dм", hours, minutes)
        } else {
            return String(format: "%dм", minutes)
        }
    }
}
