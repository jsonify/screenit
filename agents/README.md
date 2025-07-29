# Claude Code Sub-Agents

This directory contains specialized sub-agents for the screenit project. Each agent is designed to handle specific tasks in isolation, providing focused expertise and maintaining clean separation of concerns.

## How Sub-Agents Work

1. **User** prompts the **Primary Agent**
2. **Primary Agent** analyzes the request and selects appropriate **Sub-Agent**
3. **Sub-Agent** executes the task in isolation
4. **Sub-Agent** reports back to **Primary Agent**  
5. **Primary Agent** reports results to **User**

## Available Agents

### Meta Agent (`meta-agent.md`)
- **Purpose**: Creates new sub-agents based on user descriptions
- **Triggers**: "create an agent", "build a new agent", "generate an agent"
- **Tools**: Write, Read
- **Use**: Generate specialized agents for your specific needs

### Code Reviewer (`code-reviewer.md`)  
- **Purpose**: Analyzes Swift code for quality and best practices
- **Triggers**: "review code", "analyze Swift code", "code review"
- **Tools**: Read, Grep, TodoWrite
- **Use**: Get comprehensive code quality feedback

### Documentation Generator (`doc-generator.md`)
- **Purpose**: Creates documentation (README, API docs, comments)
- **Triggers**: "generate docs", "create documentation", "write README"  
- **Tools**: Read, Write, Grep, Glob
- **Use**: Generate project documentation automatically

## Agent Structure

Each agent follows this structure:

```markdown
# Agent Name - Brief Description

**Agent Name:** kebab-case-name
**Description:** Trigger conditions and usage guidance
**Tools:** List of allowed tools
**System Prompt:** Complete instructions for the agent
```

## Key Principles

1. **Single Responsibility**: Each agent does one thing well
2. **Isolated Context**: Agents have no memory of previous conversations
3. **Clear Communication**: Agents report back to primary agent, not user
4. **Tool Restrictions**: Each agent only has access to specified tools
5. **Reusability**: Agents can be used across different contexts

## Creating New Agents

Use the meta-agent to create new specialized agents:

```
Create an agent that [describe what you want the agent to do]
```

The meta-agent will generate a properly structured agent file following all best practices.

## Best Practices

- Keep agent descriptions specific and clear
- Use descriptive trigger phrases in descriptions  
- Limit tools to only what's necessary
- Design for reusability across contexts
- Test agents with simple requests first
- Document any special variables or requirements