//
//  ContentView.swift
//  TimeDistributionSlider
//
//  Created by Sergey on 15.01.2026.
//

import SwiftUI
import TimeDistributionSlider

// MARK: - ContentView
struct ContentView: View {
    @State private var clients: [Client] = [
        Client(name: "Клиент 1"),
        Client(name: "Клиент 2"),
        Client(name: "Клиент 3")
    ]
    @State private var clientProportions: [UUID: Double] = [:]
    @State private var totalDuration: TimeInterval = 8 * 3600 // 8 часов
    @State private var numberOfClients: Int = 3
    @State private var minShare: Double = 0.05 // Минимальная доля на клиента (5%)
    @State private var enablePush: Bool = true // Разрешить проталкивание разделителей
    @State private var maxClients: Int = 20 // Максимальное количество клиентов
    
    var body: some View {
     
            ScrollView {
                VStack(spacing: 20) {
                    // Controls
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Настройки тестирования")
                            .font(.headline)
                        
                        // Количество клиентов
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Количество клиентов: \(numberOfClients)")
                                .font(.subheadline)
                            Slider(value: Binding(
                                get: { Double(numberOfClients) },
                                set: { newValue in
                                    numberOfClients = Int(newValue)
                                    updateClients()
                                }
                            ), in: 2...Double(maxClients), step: 1)
                        }
                        
                        // Максимальное количество клиентов
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Макс. клиентов: \(maxClients)")
                                .font(.subheadline)
                            Slider(value: Binding(
                                get: { Double(maxClients) },
                                set: { newValue in
                                    maxClients = Int(newValue)
                                    if numberOfClients > maxClients {
                                        numberOfClients = maxClients
                                        updateClients()
                                    }
                                }
                            ), in: 2...50, step: 1)
                        }
                        
                        // Общая длительность
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Общая длительность: \(formatDuration(totalDuration))")
                                .font(.subheadline)
                            Slider(value: $totalDuration, in: 3600...86400, step: 3600)
                        }
                        
                        // Минимальное расстояние между разделителями
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Мин. доля на клиента: \(String(format: "%.1f", minShare * 100))%")
                                .font(.subheadline)
                            Slider(value: $minShare, in: 0.01...0.2, step: 0.01)
                        }
                        
                        // Разрешить проталкивание
                        Toggle("Разрешить проталкивание разделителей", isOn: $enablePush)
                            .font(.subheadline)
                        
                        // Кнопка равномерного распределения
                        Button("Равномерно распределить") {
                            equalizeProportions()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                    
                    // TimeDistributionSlider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Распределение времени")
                            .font(.headline)
                        
                        TimeDistributionSlider(
                            totalDuration: totalDuration,
                            clients: clients,
                            proportions: $clientProportions,
                            minShare: minShare,
                            enablePush: enablePush
                        )
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Детальная информация
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Детали распределения")
                            .font(.headline)
                        
                        ForEach(clients) { client in
                            let share = clientProportions[client.id] ?? 0
                            let time = totalDuration * share
                            let percentage = share * 100
                            
                            HStack {
                                Text(client.name)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(formatDuration(time))")
                                    .font(.subheadline)
                                    .monospacedDigit()
                                Text("(\(String(format: "%.1f", percentage))%)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Time Distribution Slider")
            .onAppear {
                initializeProportions()
            }
       
    }
    
    private func updateClients() {
        let oldClients = clients // Сохраняем существующих клиентов
        clients = Array(0..<numberOfClients).map { index in
            if index < oldClients.count {
                // Сохраняем существующих клиентов
                return oldClients[index]
            } else {
                // Генерируем имя динамически
                return Client(name: "Клиент \(index + 1)")
            }
        }
        initializeProportions()
    }
    
    private func initializeProportions() {
        // Инициализируем пропорции, если их нет
        if clientProportions.isEmpty || clients.count != clientProportions.count {
            equalizeProportions()
        } else {
            // Проверяем, что все клиенты имеют пропорции
            for client in clients {
                if clientProportions[client.id] == nil {
                    equalizeProportions()
                    break
                }
            }
        }
    }
    
    private func equalizeProportions() {
        let equalShare = 1.0 / Double(clients.count)
        clientProportions = Dictionary(uniqueKeysWithValues: clients.map { ($0.id, equalShare) })
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

#Preview {
    ContentView()
}
