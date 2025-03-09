# RooFlow Installation Instructions

## Required Files to Copy
1. Mode Configuration Files (to project root):
   ```
   .clinerules-architect
   .clinerules-ask
   .clinerules-code
   .clinerules-debug
   .clinerules-test
   .clinerules-igor    # Important: Igor mode configuration
   ```

2. Mode Configuration File:
   ```
   .roomodes
   ```

3. System Prompt Files:
   Create `.roo` directory and copy these files:
   ```
   .roo/system-prompt-architect
   .roo/system-prompt-ask
   .roo/system-prompt-code
   .roo/system-prompt-debug
   .roo/system-prompt-test
   .roo/system-prompt-igor    # Important: Required for Igor mode
   ```

## Installation Steps

1. **Create Project Structure**
   ```bash
   mkdir -p [target-dir]/.roo
   ```

2. **Copy Configuration Files**
   Copy from current directory:
   ```bash
   cp .clinerules-* [target-dir]/
   cp .roomodes [target-dir]/
   cp .roo/system-prompt-* [target-dir]/.roo/
   ```

3. **Initialize RooFlow**
   - Open the project in VS Code
   - Start a new Roo conversation
   - Switch to Architect mode
   - The Memory Bank will initialize on first use

## Verification
After installation, you should see:
1. All configuration files in the correct locations:
   - All .clinerules-* files including .clinerules-igor
   - .roomodes file
2. `.roo` directory with system prompt files:
   - All system-prompt-* files including system-prompt-igor
3. Memory Bank will initialize when you start using Roo

## Next Steps
Once files are copied:
1. Open project in VS Code
2. Start new Roo conversation
3. Let Architect mode initialize the Memory Bank
4. Begin using RooFlow's mode system

## Important Notes
- Always ensure Igor mode files are included:
  - .clinerules-igor in root directory
  - system-prompt-igor in .roo directory
- Igor mode provides strategic thinking and practical solutions
- Igor mode requires both configuration and system prompt to function properly

Note: Memory Bank initialization will be handled in a separate Roo instance as requested.