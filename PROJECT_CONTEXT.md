# Reserve Manager - Project Context

## Project Overview
A sophisticated personal finance application for managing tiered cash reserves with GUI and CLI interfaces.

**Current Status:** Production-ready application with modern Tkinter GUI, comprehensive allocation algorithms, and macOS app building capability.

## Core Purpose
- Manage 6-tier cash reserve system for personal financial planning
- Automated allocation across accounts based on priorities, weights, and caps
- Professional features including transaction history and analytics
- Native macOS app distribution

## Key Business Logic
1. **Priority-based allocation**: Lower priority tiers fill first (Tier 1 before Tier 2)
2. **Account routing**: Each tier has a preferred account for new funds
3. **Weight-based distribution**: Within tiers, funds distributed by allocation weights
4. **Account caps**: Individual accounts can have maximum targets
5. **Rebalancing**: Suggests moves between accounts for optimization

## Current Architecture
- **Core Engine** (`reserve_manager.py`): Data models, allocation logic, CLI
- **Enhanced Features** (`reserve_manager_enhanced.py`): Transactions, history, analytics
- **GUI Application** (`reserve_manager_pro_v3.py`): Modern Tkinter interface
- **Data Storage**: JSON-based persistence with schema versioning

## Recent Development Activity (August 2025)

### Version 3.2 Release
- ✅ **Data Persistence Fix**: Fixed load_or_init_plan() to properly save/load user data
- ✅ **Save As/Load Functionality**: Complete file management with keyboard shortcuts (⇧⌘S, ⌘O)
- ✅ **New Plan Fix**: Creates clean templates instead of retaining old data
- ✅ **Version Updates**: All in-app help and version numbers updated to v3.2
- ✅ **Documentation**: Comprehensive workflow documentation for future releases

### Repository Health Restoration
- ✅ **Major Git Cleanup**: Resolved repository bloat (1569 objects → optimized)
- ✅ **Enhanced .gitignore**: Prevents future build artifact pollution
- ✅ **Push Issues Resolved**: Git operations now work normally after garbage collection
- ✅ **Size Reduction**: Repository reduced from 337MB to 127MB packed objects
- Cleaned up project directory, removing obsolete files and build artifacts

## Known Working State
- Tests pass with `pytest -q`
- macOS build works with `./build_mac.sh`
- GUI application launches and functions correctly
- Core allocation algorithms are stable and tested

## Active Development Areas
- GUI refinements and user experience improvements
- Enhanced analytics and reporting features
- Cross-platform compatibility (currently focused on macOS)

## Important Implementation Details
- Uses dataclasses for type safety
- Supports both CLI and GUI operation modes  
- Implements proper logging to platform-specific directories
- JSON schema includes migration capability for future updates
- ttkbootstrap theming with graceful fallback to standard ttk