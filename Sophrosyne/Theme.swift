//
//  Theme.swift
//  Sophrosyne
//
//  Created by Greg Miller on 9/30/25.
//

import SwiftUI

/// Sophrosyne Theme System
/// Following Sophrosyne rules: Balanced integration with proper error handling
/// Theme: Balanced Coder - Harmonious blend of serenity and functionality
struct SophrosyneTheme {
    
    // MARK: - Color Palette
    
    /// Primary color - Serene blue for main UI elements
    /// RGB: (0.66, 0.84, 0.99) - Calming sky blue
    static let primary = Color(red: 0.66, green: 0.84, blue: 0.99)
    
    /// Accent color - Warm gold for highlights and interactive elements
    /// RGB: (0.96, 0.82, 0.24) - Gentle golden yellow
    static let accent = Color(red: 0.96, green: 0.82, blue: 0.24)
    
    /// Background color - Pure white for clean, serene appearance
    static let background = Color.white
    
    /// Surface color - Slightly off-white for subtle depth
    static let surface = Color(red: 0.98, green: 0.98, blue: 0.99)
    
    /// Text colors for hierarchy
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color(red: 0.6, green: 0.6, blue: 0.6)
    
    /// Status colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    
    // MARK: - Typography
    
    /// Custom font system with serif design for elegant readability
    struct Typography {
        
        /// Body text with serif design and medium weight
        static let body = Font.system(.body, design: .serif, weight: .medium)
        
        /// Headline text with serif design and semibold weight
        static let headline = Font.system(.headline, design: .serif, weight: .semibold)
        
        /// Title text with serif design and bold weight
        static let title = Font.system(.title, design: .serif, weight: .bold)
        
        /// Title2 text with serif design and bold weight
        static let title2 = Font.system(.title2, design: .serif, weight: .bold)
        
        /// Title3 text with serif design and bold weight
        static let title3 = Font.system(.title3, design: .serif, weight: .bold)
        
        /// Large title for main headings
        static let largeTitle = Font.system(.largeTitle, design: .serif, weight: .bold)
        
        /// Caption text with serif design and regular weight
        static let caption = Font.system(.caption, design: .serif, weight: .regular)
        
        /// Callout text for emphasis
        static let callout = Font.system(.callout, design: .serif, weight: .medium)
    }
    
    // MARK: - Spacing
    
    /// Consistent spacing system for balanced layout
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    /// Consistent corner radius system
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }
}

// MARK: - Color Extensions

extension Color {
    
    /// Sophrosyne primary color
    static let sophrosynePrimary = SophrosyneTheme.primary
    
    /// Sophrosyne accent color
    static let sophrosyneAccent = SophrosyneTheme.accent
    
    /// Sophrosyne background color
    static let sophrosyneBackground = SophrosyneTheme.background
    
    /// Sophrosyne surface color
    static let sophrosyneSurface = SophrosyneTheme.surface
    
    /// Sophrosyne text colors
    static let sophrosyneTextPrimary = SophrosyneTheme.textPrimary
    static let sophrosyneTextSecondary = SophrosyneTheme.textSecondary
    static let sophrosyneTextTertiary = SophrosyneTheme.textTertiary
    
    /// Sophrosyne status colors
    static let sophrosyneSuccess = SophrosyneTheme.success
    static let sophrosyneWarning = SophrosyneTheme.warning
    static let sophrosyneError = SophrosyneTheme.error
}

// MARK: - Font Extensions

extension Font {
    
    /// Sophrosyne body font with serif design
    static let sophrosyneBody = SophrosyneTheme.Typography.body
    
    /// Sophrosyne headline font with serif design
    static let sophrosyneHeadline = SophrosyneTheme.Typography.headline
    
    /// Sophrosyne title font with serif design
    static let sophrosyneTitle = SophrosyneTheme.Typography.title
    
    /// Sophrosyne title2 font with serif design
    static let sophrosyneTitle2 = SophrosyneTheme.Typography.title2
    
    /// Sophrosyne title3 font with serif design
    static let sophrosyneTitle3 = SophrosyneTheme.Typography.title3
    
    /// Sophrosyne large title font with serif design
    static let sophrosyneLargeTitle = SophrosyneTheme.Typography.largeTitle
    
    /// Sophrosyne caption font with serif design
    static let sophrosyneCaption = SophrosyneTheme.Typography.caption
    
    /// Sophrosyne callout font with serif design
    static let sophrosyneCallout = SophrosyneTheme.Typography.callout
}

// MARK: - Shadow ViewModifier

/// Sophrosyne shadow modifier for consistent drop shadows
/// Following Sophrosyne rules: Balanced integration with proper error handling
struct SophrosyneShadow: ViewModifier {
    
    /// Shadow opacity (0.1 for subtle effect)
    let opacity: Double
    
    /// Shadow radius (4 for balanced depth)
    let radius: CGFloat
    
    /// Shadow offset (default: 0, 2 for subtle elevation)
    let offset: CGSize
    
    init(opacity: Double = 0.1, radius: CGFloat = 4, offset: CGSize = CGSize(width: 0, height: 2)) {
        self.opacity = opacity
        self.radius = radius
        self.offset = offset
    }
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: .black.opacity(opacity),
                radius: radius,
                x: offset.width,
                y: offset.height
            )
    }
}

// MARK: - View Extensions

extension View {
    
    /// Apply Sophrosyne shadow with default parameters
    func sophrosyneShadow(
        opacity: Double = 0.1,
        radius: CGFloat = 4,
        offset: CGSize = CGSize(width: 0, height: 2)
    ) -> some View {
        self.modifier(SophrosyneShadow(opacity: opacity, radius: radius, offset: offset))
    }
    
    /// Apply Sophrosyne primary background
    func sophrosynePrimaryBackground() -> some View {
        self.background(Color.sophrosynePrimary)
    }
    
    /// Apply Sophrosyne surface background
    func sophrosyneSurfaceBackground() -> some View {
        self.background(Color.sophrosyneSurface)
    }
    
    /// Apply Sophrosyne accent foreground
    func sophrosyneAccentForeground() -> some View {
        self.foregroundStyle(Color.sophrosyneAccent)
    }
    
    /// Apply Sophrosyne primary foreground
    func sophrosynePrimaryForeground() -> some View {
        self.foregroundStyle(Color.sophrosynePrimary)
    }
    
    /// Apply Dynamic Type scaling to Sophrosyne fonts
    /// Following Sophrosyne rules: Balanced integration with accessibility
    func scaledFont(_ font: Font) -> some View {
        self.font(font)
            .dynamicTypeSize(.accessibility1 ... .accessibility5)
    }
}

// MARK: - Environment Key

/// Environment key for theme configuration
struct SophrosyneThemeKey: EnvironmentKey {
    static let defaultValue: SophrosyneTheme = SophrosyneTheme()
}

extension EnvironmentValues {
    var sophrosyneTheme: SophrosyneTheme {
        get { self[SophrosyneThemeKey.self] }
        set { self[SophrosyneThemeKey.self] = newValue }
    }
}

// MARK: - Theme Environment Modifier

/// Environment modifier to apply Sophrosyne theme throughout the view hierarchy
struct SophrosyneThemeModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .environment(\.sophrosyneTheme, SophrosyneTheme())
    }
}

extension View {
    
    /// Apply Sophrosyne theme environment to the entire view hierarchy
    func sophrosyneTheme() -> some View {
        self.modifier(SophrosyneThemeModifier())
    }
}

// MARK: - Custom Toggle Switch

/// Sophrosyne custom toggle switch with accent fill and secondary track
/// Following Sophrosyne rules: Balanced integration with proper error handling
struct SophrosyneToggle: View {
    @Binding var isOn: Bool
    let label: String
    let subtitle: String?
    
    init(_ label: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.label = label
        self.subtitle = subtitle
        self._isOn = isOn
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: SophrosyneTheme.Spacing.xs) {
                Text(label)
                    .font(.sophrosyneHeadline)
                    .foregroundStyle(Color.sophrosyneTextPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.sophrosyneCaption)
                        .foregroundStyle(Color.sophrosyneTextSecondary)
                }
            }
            
            Spacer()
            
            // Custom toggle switch
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isOn.toggle()
                }
            }) {
                ZStack {
                    // Track
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.sophrosyneTextSecondary.opacity(0.3))
                        .frame(width: 50, height: 30)
                    
                    // Thumb
                    Circle()
                        .fill(Color.sophrosyneAccent)
                        .frame(width: 26, height: 26)
                        .offset(x: isOn ? 10 : -10)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, SophrosyneTheme.Spacing.lg)
        .padding(.vertical, SophrosyneTheme.Spacing.md)
        .background(.white)
        .cornerRadius(SophrosyneTheme.CornerRadius.md)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - CardView Component

/// Sophrosyne CardView component for form elements
/// Following Sophrosyne rules: Balanced integration with proper error handling
struct SophrosyneCardView<Content: View>: View {
    let content: Content
    @State private var isFocused: Bool = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(SophrosyneTheme.Spacing.md)
            .background(.white.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: SophrosyneTheme.CornerRadius.lg))
            .sophrosyneShadow()
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isFocused = true
                }
                
                // Reset focus after a brief moment
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFocused = false
                    }
                }
            }
    }
}
