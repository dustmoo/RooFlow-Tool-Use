# RooFlow for WH Projects

## Overview
RooFlow is a configuration management system for Roo-Code that enables consistent development practices across WH projects. This guide explains how to install and use RooFlow in WH projects.

## Quick Start

### Local Setup
1. Create a working directory:
```bash
mkdir -p ~/Sites/RooFlow
cd ~/Sites/RooFlow
```

2. Copy the installation files:
- `install_rooflow.sh`
- `rooflow_config.json`
- `.clinerules-*` files
- `.roomodes`
- `.roo/` directory with system prompts

3. Make the installation script executable:
```bash
chmod +x install_rooflow.sh
```

4. Configure your local projects:
```bash
# Edit rooflow_config.json with your project paths
code rooflow_config.json
```

### Installation
1. Single Project Installation:
```bash
./install_rooflow.sh -p /path/to/project
```

2. Install to All WH Projects:
```bash
./install_rooflow.sh --all
```

### Backup and Restore
- Create backup:
```bash
./install_rooflow.sh -b /path/to/project
```

- List backups:
```bash
./install_rooflow.sh -l /path/to/project
```

- Restore from backup:
```bash
./install_rooflow.sh -r /path/to/project /path/to/backup/file.tar.gz
```

## Configured Projects
RooFlow is configured for the following WH projects:
- wh-meridian-interface (Python)
- wh-lighthouse-serp-scrape-lambda (Python)
- microsoft-graph-mcp (Node.js)

To add a new project, update `rooflow_config.json`.

## Using with Roo-Code

### Available Modes
1. **Architect Mode**
   - Strategic planning and system design
   - Initialize new projects
   - Configure system components

2. **Code Mode**
   - Code generation and review
   - Refactoring assistance
   - Documentation generation

3. **Ask Mode**
   - General questions
   - Project clarification
   - Quick reference

4. **Igor Mode**
   - Technical assistance
   - Process automation
   - Strategic implementation

5. **Communication Support Mode**
   - Documentation review
   - Communication clarity
   - Message formatting

### Best Practices

1. **Project Initialization**
   ```bash
   # 1. Install RooFlow
   ./install_rooflow.sh -p /path/to/project

   # 2. Open in VS Code
   code /path/to/project

   # 3. Start Roo conversation
   # 4. Switch to Architect mode
   # 5. Initialize Memory Bank
   ```

2. **Development Workflow**
   - Use Architect mode for system design
   - Switch to Code mode for implementation
   - Use Ask mode for quick questions
   - Use Igor mode for process automation
   - Use Communication Support for documentation

3. **Configuration Management**
   - Keep backups before major changes
   - Use version control for configurations
   - Update shared settings in `rooflow_config.json`

## Memory Bank
Each project maintains its own Memory Bank in the `memory-bank` directory:
- `activeContext.md`: Current project context
- `systemPatterns.md`: Reusable patterns
- Additional project-specific memory files

## Maintenance

### Adding New Projects
1. Update `rooflow_config.json`:
```json
{
  "managed_projects": [
    {
      "path": "/path/to/new/project",
      "type": "python|nodejs",
      "description": "Project description"
    }
  ]
}
```

2. Run installation:
```bash
./install_rooflow.sh -p /path/to/new/project
```

### Updating Configurations
1. Create backup:
```bash
./install_rooflow.sh -b /path/to/project
```

2. Make changes

3. Test changes:
```bash
./install_rooflow.sh -p /path/to/project
```

4. Commit to version control

## Version Control
- All RooFlow configurations are version controlled
- Branch: `wh-rooflow`
- Include all `.clinerules-*` files
- Include `.roomodes`
- Include system prompts in `.roo/`
- Include `rooflow_config.json`

## Support
For issues or questions:
1. Use Ask mode for quick help
2. Check project documentation
3. Review Memory Bank for context
4. Contact system administrators

## Contributing
1. Create feature branch from `wh-rooflow`
2. Make changes
3. Test with multiple projects
4. Create pull request
5. Update documentation