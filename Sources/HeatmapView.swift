import SwiftUI

struct HeatmapView: View {
    @ObservedObject var tracker: KeyTracker
    @Binding var selectedDate: Date
    
    // State for year selection
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    // State for hover info
    @State private var hoveredDay: (date: Date, count: Int)?
    
    private let calendar = Calendar.current
    
    // Labels
    private let weekDays = ["", "Mon", "", "Wed", "", "Fri", ""]
    private let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        f.locale = Locale(identifier: "en_US")
        return f
    }()
    
    // Compute dates for the entire selected year
    private var dates: [Date] {
        var dates: [Date] = []
        
        // Construct Jan 1st of selectedYear
        var components = DateComponents()
        components.year = selectedYear
        components.month = 1
        components.day = 1
        guard let startOfYear = calendar.date(from: components) else { return [] }
        
        // Construct Dec 31st of selectedYear
        components.month = 12
        components.day = 31
        guard let endOfYear = calendar.date(from: components) else { return [] }
        
        // Align start date to the preceding Sunday (or firstWeekday)
        let weekdayOfStart = calendar.component(.weekday, from: startOfYear)
        let daysToSubtract = weekdayOfStart - calendar.firstWeekday
        let offsetStart = (daysToSubtract + 7) % 7
        let alignedStartDate = calendar.date(byAdding: .day, value: -offsetStart, to: startOfYear) ?? startOfYear
        
        // Align end date to the following Saturday (or end of week)
        var currentDate = alignedStartDate
        while true {
            dates.append(currentDate)
            
            let isAfterEnd = currentDate > endOfYear
            let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            let nextWeekday = calendar.component(.weekday, from: nextDay)
            
            if isAfterEnd && nextWeekday == calendar.firstWeekday {
                break
            }
            currentDate = nextDay
        }
        
        return dates
    }
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    var body: some View {
        VStack(spacing: 8) {
            // Header with Year Picker
            HStack {
                if let hovered = hoveredDay {
                    Text("\(dateFormatter.string(from: hovered.date)): \(hovered.count)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                    Spacer()
                } else {
                    Spacer()
                }
                
                HStack {
                    Button(action: { selectedYear -= 1 }) {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.plain)
                    
                    Text(String(format: "%d", selectedYear))
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 50)
                        .multilineTextAlignment(.center)
                    
                    Button(action: { selectedYear += 1 }) {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedYear >= calendar.component(.year, from: Date()))
                }
                .padding(4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
            }
            .padding(.bottom, 4)
            
            HStack(alignment: .top, spacing: 4) {
                // Weekday Labels
                VStack(alignment: .leading, spacing: 3) {
                    Spacer().frame(height: 20) // Space for month labels area
                    ForEach(0..<7, id: \.self) { i in
                        Text(weekDays[i])
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .frame(height: 12)
                    }
                }
                .padding(.top, 4)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        // Month Labels (Absolute Positioning)
                        ZStack(alignment: .topLeading) {
                            // Invisible spacer to reserve height
                            Text("Jan").font(.system(size: 10)).hidden()
                            
                            ForEach(monthLabels(dates: dates), id: \.offset) { item in
                                Text(item.text)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .offset(x: item.xPosition)
                            }
                        }
                        
                        // The Grid
                        LazyHGrid(rows: Array(repeating: GridItem(.fixed(12), spacing: 3), count: 7), spacing: 3) {
                            ForEach(dates, id: \.self) { date in
                                let dateString = dateFormatter.string(from: date)
                                let count = tracker.dailyHistory[dateString]?.totalKeystrokes ?? 0
                                
                                let isInYear = calendar.component(.year, from: date) == selectedYear
                                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                                let isToday = calendar.isDateInToday(date)
                                
                                Rectangle()
                                    .fill(isInYear ? color(for: count) : Color.clear)
                                    .frame(width: 12, height: 12)
                                    .cornerRadius(2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 2)
                                            .stroke(
                                                isSelected ? Color.primary : (isToday ? Color.secondary.opacity(0.5) : Color.clear),
                                                lineWidth: isSelected ? 1 : (isToday ? 1 : 0)
                                            )
                                    )
                                    .help("\(dateString): \(count) keystrokes")
                                    .onHover { isHovering in
                                        if isHovering {
                                            hoveredDay = (date, count)
                                        } else if hoveredDay?.date == date {
                                            hoveredDay = nil
                                        }
                                    }
                                    .onTapGesture {
                                        selectedDate = date
                                    }
                                    .id(date)
                            }
                        }
                    }
                    .padding(.bottom, 4)
                    .onAppear {
                        if let last = dates.last {
                            // proxy.scrollTo(last, anchor: .trailing) // Removed proxy dependency
                        }
                    }
                }
            }
            .frame(height: 140)
        }
    }
    
    struct MonthLabel {
        let text: String
        let offset: Int // column index
        let xPosition: CGFloat
    }
    
    private func monthLabels(dates: [Date]) -> [MonthLabel] {
        var labels: [MonthLabel] = []
        var currentMonth = -1
        
        let boxSize: CGFloat = 12
        let spacing: CGFloat = 3
        let colWidth: CGFloat = boxSize + spacing
        
        for (index, date) in dates.enumerated() where index % 7 == 0 {
            let month = calendar.component(.month, from: date)
            let day = calendar.component(.day, from: date)
            let year = calendar.component(.year, from: date)
            
            // Only consider columns that belong to the selected year
            if year != selectedYear { continue }
            
            if month != currentMonth {
                // To avoid label clutter, only add if it's the first week of the month
                // or close to it (day <= 7)
                if day <= 14 {
                    let colIndex = index / 7
                    let xPos = CGFloat(colIndex) * colWidth
                    let text = monthFormatter.string(from: date)
                    labels.append(MonthLabel(text: text, offset: colIndex, xPosition: xPos))
                    currentMonth = month
                }
            }
        }
        return labels
    }
    
    private func color(for count: Int) -> Color {
        if count == 0 { return Color.secondary.opacity(0.1) }
        if count < 100 { return Color.green.opacity(0.3) }
        if count < 500 { return Color.green.opacity(0.5) }
        if count < 2000 { return Color.green.opacity(0.7) }
        return Color.green
    }
}
