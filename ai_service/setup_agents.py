"""
Setup script to create the Agentic AI directory structure.
Run this script from the ai_service directory to create necessary folders.

Usage: python setup_agents.py
"""

import os
import sys

def create_agent_structure():
    """Create the agent directory structure"""
    base_dir = os.path.dirname(os.path.abspath(__file__))
    agents_dir = os.path.join(base_dir, "app", "agents")
    
    # Create agents directory
    os.makedirs(agents_dir, exist_ok=True)
    print(f"Created directory: {agents_dir}")
    
    # Create empty __init__.py if it doesn't exist
    init_file = os.path.join(agents_dir, "__init__.py")
    if not os.path.exists(init_file):
        with open(init_file, 'w') as f:
            f.write('"""Agentic AI Framework for Preventive Healthcare"""\n')
        print(f"Created: {init_file}")
    
    print("Agent directory structure created successfully!")
    print(f"Now create agent files in: {agents_dir}")
    return agents_dir

if __name__ == "__main__":
    create_agent_structure()
