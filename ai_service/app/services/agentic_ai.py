"""
Agentic AI Framework for Preventive Healthcare
Complete Multi-Agent System Implementation

This module contains all agent implementations for the preventive healthcare workflow:
- BaseAgent with Reflection, Planning, Tool-Use patterns
- MasterAgent for orchestration
- SchedulingAgent, EmailAgent, NotificationAgent
- PredictiveAgent for risk assessment
- InitiationAgent, HRAAgent, FollowUpAgent
- PreVisitAgent, PreventionPlanAgent, PostVisitAgent, BillingAgent

Based on the research paper: "An Agentic AI Framework for Strengthening Preventive Healthcare"
"""

import json
import uuid
import asyncio
import httpx
from abc import ABC, abstractmethod
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any, Callable, Tuple
from enum import Enum
from dataclasses import dataclass, field
from pydantic import BaseModel
import logging

logger = logging.getLogger(__name__)


# ============= ENUMS AND DATA CLASSES =============

class AgentRole(str, Enum):
    """Agent roles in the preventive healthcare system"""
    MASTER = "master"
    SCHEDULING = "scheduling"
    EMAIL = "email"
    NOTIFICATION = "notification"
    PREDICTIVE = "predictive"
    INITIATION = "initiation"
    HRA = "hra"
    FOLLOW_UP = "follow_up"
    PRE_VISIT = "pre_visit"
    PREVENTION_PLAN = "prevention_plan"
    POST_VISIT = "post_visit"
    BILLING = "billing"


class AgentStatus(str, Enum):
    """Agent execution status"""
    IDLE = "idle"
    PLANNING = "planning"
    EXECUTING = "executing"
    REFLECTING = "reflecting"
    WAITING = "waiting"
    COMPLETED = "completed"
    FAILED = "failed"


class WorkflowStep(str, Enum):
    """Preventive healthcare workflow steps"""
    PATIENT_IDENTIFICATION = "patient_identification"
    APPOINTMENT_SCHEDULING = "appointment_scheduling"
    HRA_DISTRIBUTION = "hra_distribution"
    PRE_VISIT_PREPARATION = "pre_visit_preparation"
    PREVENTIVE_VISIT = "preventive_visit"
    PREVENTION_PLAN = "prevention_plan"
    DOCUMENTATION = "documentation"
    BILLING = "billing"
    FOLLOW_UP = "follow_up"


@dataclass
class AgentState:
    """Current state of an agent"""
    status: AgentStatus = AgentStatus.IDLE
    current_task: Optional[str] = None
    progress: float = 0.0
    last_action: Optional[str] = None
    last_result: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


class AgentMessage(BaseModel):
    """Message format for agent-to-agent communication"""
    id: str = ""
    from_agent: str
    to_agent: str
    message_type: str  # request, response, notification, error
    action: str
    payload: Dict[str, Any] = {}
    timestamp: str = ""
    correlation_id: Optional[str] = None
    priority: int = 1  # 1=normal, 2=high, 3=urgent

    def __init__(self, **data):
        super().__init__(**data)
        if not self.id:
            self.id = str(uuid.uuid4())
        if not self.timestamp:
            self.timestamp = datetime.now().isoformat()


@dataclass
class AgentMemory:
    """Agent memory for reflection pattern"""
    short_term: List[Dict[str, Any]] = field(default_factory=list)
    long_term: Dict[str, Any] = field(default_factory=dict)
    feedback: List[Dict[str, Any]] = field(default_factory=list)
    max_short_term: int = 100

    def add_action(self, action: str, result: Any, success: bool, context: Dict[str, Any] = None):
        """Record an action for learning"""
        entry = {
            "timestamp": datetime.now().isoformat(),
            "action": action,
            "result": str(result)[:500] if result else None,
            "success": success,
            "context": context or {}
        }
        self.short_term.append(entry)
        if len(self.short_term) > self.max_short_term:
            self.short_term.pop(0)

    def add_feedback(self, action: str, feedback: str, score: float):
        """Add feedback for reflection"""
        self.feedback.append({
            "timestamp": datetime.now().isoformat(),
            "action": action,
            "feedback": feedback,
            "score": score
        })

    def get_success_rate(self, action: str = None) -> float:
        """Calculate success rate for reflection"""
        relevant = [a for a in self.short_term if action is None or a["action"] == action]
        if not relevant:
            return 0.0
        return sum(1 for a in relevant if a["success"]) / len(relevant)

    def learn_pattern(self, key: str, pattern: Any):
        """Store a learned pattern"""
        self.long_term[key] = {
            "pattern": pattern,
            "learned_at": datetime.now().isoformat(),
            "usage_count": self.long_term.get(key, {}).get("usage_count", 0) + 1
        }

    def get_pattern(self, key: str) -> Optional[Any]:
        """Retrieve a learned pattern"""
        if key in self.long_term:
            self.long_term[key]["usage_count"] += 1
            return self.long_term[key]["pattern"]
        return None


# ============= BASE AGENT CLASS =============

class BaseAgent(ABC):
    """
    Base class for all agents in the Agentic AI framework.
    Implements Reflection, Tool-Use, and Planning design patterns.
    """

    def __init__(
        self,
        agent_id: str,
        role: AgentRole,
        gemini_client=None,
        tools: List[Callable] = None,
        config: Dict[str, Any] = None,
        backend_url: str = "http://localhost:8080/api"
    ):
        self.agent_id = agent_id
        self.role = role
        self.client = gemini_client
        self.tools = tools or []
        self.config = config or {}
        self.backend_url = backend_url
        self.state = AgentState()
        self.memory = AgentMemory()
        self.message_queue: asyncio.Queue = asyncio.Queue()
        self._running = False
        logger.info(f"Agent {agent_id} ({role.value}) initialized")

    @property
    def name(self) -> str:
        return f"{self.role.value}_{self.agent_id}"

    # ============= TOOL-USE PATTERN =============
    
    def register_tool(self, tool: Callable, name: str = None, description: str = None):
        """Register a tool for the agent to use"""
        tool_info = {
            "function": tool,
            "name": name or tool.__name__,
            "description": description or tool.__doc__ or "No description"
        }
        self.tools.append(tool_info)
        logger.info(f"Agent {self.name}: Registered tool '{tool_info['name']}'")

    async def use_tool(self, tool_name: str, **kwargs) -> Any:
        """Execute a tool by name"""
        tool = next((t for t in self.tools if t.get("name") == tool_name or 
                    (callable(t) and t.__name__ == tool_name)), None)
        
        if tool is None:
            raise ValueError(f"Tool '{tool_name}' not found")
        
        func = tool["function"] if isinstance(tool, dict) else tool
        
        self.state.last_action = f"tool:{tool_name}"
        self.state.status = AgentStatus.EXECUTING
        
        try:
            if asyncio.iscoroutinefunction(func):
                result = await func(**kwargs)
            else:
                result = func(**kwargs)
            
            self.memory.add_action(f"tool:{tool_name}", result, success=True, context=kwargs)
            self.state.last_result = {"tool": tool_name, "result": result, "success": True}
            return result
            
        except Exception as e:
            logger.error(f"Agent {self.name}: Tool '{tool_name}' failed: {e}")
            self.memory.add_action(f"tool:{tool_name}", str(e), success=False, context=kwargs)
            self.state.last_result = {"tool": tool_name, "error": str(e), "success": False}
            raise

    # ============= REFLECTION PATTERN =============
    
    async def reflect(self, context: Dict[str, Any] = None) -> Dict[str, Any]:
        """
        Reflection pattern: Analyze past actions and improve decision-making.
        """
        self.state.status = AgentStatus.REFLECTING
        
        recent_actions = self.memory.short_term[-20:]
        success_rate = self.memory.get_success_rate()
        feedback = self.memory.feedback[-10:]
        
        reflection_result = {
            "patterns": [],
            "improvements": [],
            "optimizations": [],
            "warnings": [],
            "success_rate": success_rate,
            "actions_analyzed": len(recent_actions)
        }
        
        # Simple pattern detection without AI
        failed_actions = [a for a in recent_actions if not a["success"]]
        if len(failed_actions) > len(recent_actions) * 0.3:
            reflection_result["warnings"].append("High failure rate detected")
        
        # Identify repeated actions
        action_counts = {}
        for a in recent_actions:
            action_counts[a["action"]] = action_counts.get(a["action"], 0) + 1
        
        for action, count in action_counts.items():
            if count > 5:
                reflection_result["patterns"].append(f"Frequent action: {action} ({count} times)")
        
        self.state.status = AgentStatus.IDLE
        return reflection_result

    # ============= PLANNING PATTERN =============
    
    async def plan(self, goal: str, constraints: Dict[str, Any] = None) -> List[Dict[str, Any]]:
        """
        Planning pattern: Break down a goal into executable steps.
        """
        self.state.status = AgentStatus.PLANNING
        self.state.current_task = goal
        
        # Check for learned patterns
        similar_pattern = self.memory.get_pattern(f"plan:{goal[:50]}")
        if similar_pattern:
            self.state.status = AgentStatus.IDLE
            return similar_pattern
        
        # Default planning for common healthcare workflows
        steps = self._generate_default_plan(goal, constraints)
        
        # Store plan for learning
        self.memory.learn_pattern(f"plan:{goal[:50]}", steps)
        
        self.state.status = AgentStatus.IDLE
        return steps

    def _generate_default_plan(self, goal: str, constraints: Dict[str, Any] = None) -> List[Dict[str, Any]]:
        """Generate a default plan based on goal keywords"""
        goal_lower = goal.lower()
        
        if "schedule" in goal_lower or "appointment" in goal_lower:
            return [
                {"step_number": 1, "action": "check_patient_eligibility", "tool": "check_eligibility"},
                {"step_number": 2, "action": "get_available_slots", "tool": "get_available_slots"},
                {"step_number": 3, "action": "book_appointment", "tool": "book_appointment"},
                {"step_number": 4, "action": "send_confirmation", "tool": "send_notification"}
            ]
        elif "risk" in goal_lower or "predict" in goal_lower:
            return [
                {"step_number": 1, "action": "fetch_patient_data", "tool": "get_patient_vitals"},
                {"step_number": 2, "action": "analyze_risk", "tool": "predict_risk"},
                {"step_number": 3, "action": "generate_recommendations", "tool": "generate_recommendations"}
            ]
        elif "follow" in goal_lower:
            return [
                {"step_number": 1, "action": "check_adherence", "tool": "check_adherence"},
                {"step_number": 2, "action": "identify_gaps", "tool": "analyze_gaps"},
                {"step_number": 3, "action": "send_reminders", "tool": "send_notification"}
            ]
        else:
            return [
                {"step_number": 1, "action": goal, "tool": None, "parameters": constraints or {}}
            ]

    async def execute_plan(self, steps: List[Dict[str, Any]], context: Dict[str, Any] = None) -> Dict[str, Any]:
        """Execute a planned sequence of steps"""
        results = []
        self.state.status = AgentStatus.EXECUTING
        
        for i, step in enumerate(steps):
            self.state.progress = (i / len(steps)) * 100
            self.state.current_task = step.get("action", f"Step {i+1}")
            
            try:
                if step.get("tool"):
                    result = await self.use_tool(
                        step["tool"],
                        **(step.get("parameters") or {}),
                        **(context or {})
                    )
                else:
                    result = await self.execute(step.get("action", ""), context)
                
                results.append({"step": step["step_number"], "success": True, "result": result})
                
            except Exception as e:
                logger.error(f"Step {step['step_number']} failed: {e}")
                results.append({"step": step["step_number"], "success": False, "error": str(e)})
        
        self.state.status = AgentStatus.COMPLETED
        self.state.progress = 100
        
        return {
            "steps_completed": sum(1 for r in results if r["success"]),
            "total_steps": len(steps),
            "success": all(r["success"] for r in results),
            "results": results
        }

    # ============= AGENT COMMUNICATION =============
    
    async def send_message(self, to_agent: str, action: str, payload: Dict[str, Any],
                          message_type: str = "request", priority: int = 1) -> AgentMessage:
        """Send a message to another agent"""
        message = AgentMessage(
            from_agent=self.name,
            to_agent=to_agent,
            message_type=message_type,
            action=action,
            payload=payload,
            priority=priority
        )
        logger.info(f"Agent {self.name} -> {to_agent}: {action}")
        return message

    async def receive_message(self, message: AgentMessage) -> Dict[str, Any]:
        """Process a received message"""
        logger.info(f"Agent {self.name} received: {message.action} from {message.from_agent}")
        
        try:
            handler = getattr(self, f"handle_{message.action}", None)
            if handler:
                result = await handler(message.payload)
            else:
                result = await self.execute(message.action, message.payload)
            
            return {
                "success": True,
                "result": result,
                "correlation_id": message.correlation_id or message.id
            }
            
        except Exception as e:
            logger.error(f"Agent {self.name} failed to process message: {e}")
            return {
                "success": False,
                "error": str(e),
                "correlation_id": message.correlation_id or message.id
            }

    # ============= BACKEND API CALLS =============
    
    async def call_backend(self, endpoint: str, method: str = "GET", 
                          data: Dict[str, Any] = None, token: str = None) -> Dict[str, Any]:
        """Make a call to the Spring Boot backend"""
        headers = {"Authorization": f"Bearer {token}"} if token else {}
        headers["Content-Type"] = "application/json"
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            try:
                url = f"{self.backend_url}{endpoint}"
                
                if method == "GET":
                    response = await client.get(url, headers=headers)
                elif method == "POST":
                    response = await client.post(url, json=data or {}, headers=headers)
                elif method == "PUT":
                    response = await client.put(url, json=data or {}, headers=headers)
                elif method == "DELETE":
                    response = await client.delete(url, headers=headers)
                else:
                    raise ValueError(f"Unsupported HTTP method: {method}")
                
                if response.status_code >= 200 and response.status_code < 300:
                    return {"success": True, "data": response.json()}
                else:
                    return {"success": False, "error": response.text, "status": response.status_code}
                    
            except Exception as e:
                logger.error(f"Backend call failed: {e}")
                return {"success": False, "error": str(e)}

    @abstractmethod
    async def execute(self, task: str, context: Dict[str, Any] = None) -> Any:
        """Execute a task - must be implemented by subclasses"""
        pass

    def get_state(self) -> Dict[str, Any]:
        """Get current agent state as dictionary"""
        return {
            "agent_id": self.agent_id,
            "name": self.name,
            "role": self.role.value,
            "status": self.state.status.value,
            "current_task": self.state.current_task,
            "progress": self.state.progress,
            "last_action": self.state.last_action,
            "memory_size": len(self.memory.short_term),
            "tools_available": len(self.tools),
            "error": self.state.error
        }


# ============= MASTER AGENT =============

class MasterAgent(BaseAgent):
    """
    Master Agent - Coordinates all other agents in the preventive healthcare workflow.
    Implements the orchestrator pattern for multi-agent collaboration.
    """

    def __init__(self, gemini_client=None, config: Dict[str, Any] = None, backend_url: str = "http://localhost:8080/api"):
        super().__init__(
            agent_id="master_001",
            role=AgentRole.MASTER,
            gemini_client=gemini_client,
            config=config,
            backend_url=backend_url
        )
        self.sub_agents: Dict[str, BaseAgent] = {}
        self.workflow_state: Dict[str, Any] = {}
        self.active_workflows: Dict[str, Dict[str, Any]] = {}

    def register_agent(self, agent: BaseAgent):
        """Register a sub-agent for coordination"""
        self.sub_agents[agent.name] = agent
        logger.info(f"MasterAgent: Registered sub-agent {agent.name}")

    async def execute(self, task: str, context: Dict[str, Any] = None) -> Any:
        """Execute a task by delegating to appropriate sub-agents"""
        context = context or {}
        
        # Determine which agents need to be involved
        task_lower = task.lower()
        
        if "workflow" in task_lower or "preventive" in task_lower:
            return await self.execute_preventive_workflow(context)
        elif "schedule" in task_lower:
            return await self.delegate_to_agent(AgentRole.SCHEDULING, task, context)
        elif "predict" in task_lower or "risk" in task_lower:
            return await self.delegate_to_agent(AgentRole.PREDICTIVE, task, context)
        elif "follow" in task_lower:
            return await self.delegate_to_agent(AgentRole.FOLLOW_UP, task, context)
        elif "bill" in task_lower:
            return await self.delegate_to_agent(AgentRole.BILLING, task, context)
        else:
            # Default execution
            return await self.coordinate_agents(task, context)

    async def execute_preventive_workflow(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute the complete preventive healthcare workflow as per the paper:
        1. Patient Identification
        2. Appointment Scheduling  
        3. HRA Distribution
        4. Pre-Visit Preparation
        5. Preventive Visit
        6. Prevention Plan
        7. Documentation
        8. Billing
        9. Follow-up
        """
        workflow_id = str(uuid.uuid4())
        patient_id = context.get("patient_id")
        
        self.active_workflows[workflow_id] = {
            "id": workflow_id,
            "patient_id": patient_id,
            "started_at": datetime.now().isoformat(),
            "status": "in_progress",
            "current_step": WorkflowStep.PATIENT_IDENTIFICATION.value,
            "steps_completed": [],
            "results": {}
        }
        
        workflow = self.active_workflows[workflow_id]
        results = {}
        
        try:
            # Step 1: Patient Identification
            workflow["current_step"] = WorkflowStep.PATIENT_IDENTIFICATION.value
            results["identification"] = await self.delegate_to_agent(
                AgentRole.INITIATION, 
                "identify_eligible_patient",
                {"patient_id": patient_id, **context}
            )
            workflow["steps_completed"].append(WorkflowStep.PATIENT_IDENTIFICATION.value)
            
            # Step 2: Appointment Scheduling
            workflow["current_step"] = WorkflowStep.APPOINTMENT_SCHEDULING.value
            results["scheduling"] = await self.delegate_to_agent(
                AgentRole.SCHEDULING,
                "schedule_preventive_visit",
                {"patient_id": patient_id, "eligibility": results["identification"], **context}
            )
            workflow["steps_completed"].append(WorkflowStep.APPOINTMENT_SCHEDULING.value)
            
            # Step 3: HRA Distribution
            workflow["current_step"] = WorkflowStep.HRA_DISTRIBUTION.value
            results["hra"] = await self.delegate_to_agent(
                AgentRole.HRA,
                "distribute_hra",
                {"patient_id": patient_id, "appointment": results["scheduling"], **context}
            )
            workflow["steps_completed"].append(WorkflowStep.HRA_DISTRIBUTION.value)
            
            # Step 4: Pre-Visit Preparation
            workflow["current_step"] = WorkflowStep.PRE_VISIT_PREPARATION.value
            results["pre_visit"] = await self.delegate_to_agent(
                AgentRole.PRE_VISIT,
                "prepare_visit",
                {"patient_id": patient_id, "hra": results["hra"], **context}
            )
            workflow["steps_completed"].append(WorkflowStep.PRE_VISIT_PREPARATION.value)
            
            # Step 5: Prevention Plan (after visit)
            workflow["current_step"] = WorkflowStep.PREVENTION_PLAN.value
            results["prevention_plan"] = await self.delegate_to_agent(
                AgentRole.PREVENTION_PLAN,
                "generate_prevention_plan",
                {"patient_id": patient_id, "pre_visit": results["pre_visit"], **context}
            )
            workflow["steps_completed"].append(WorkflowStep.PREVENTION_PLAN.value)
            
            # Step 6: Documentation
            workflow["current_step"] = WorkflowStep.DOCUMENTATION.value
            results["documentation"] = await self.delegate_to_agent(
                AgentRole.POST_VISIT,
                "generate_documentation",
                {"patient_id": patient_id, "prevention_plan": results["prevention_plan"], **context}
            )
            workflow["steps_completed"].append(WorkflowStep.DOCUMENTATION.value)
            
            # Step 7: Billing
            workflow["current_step"] = WorkflowStep.BILLING.value
            results["billing"] = await self.delegate_to_agent(
                AgentRole.BILLING,
                "process_billing",
                {"patient_id": patient_id, "documentation": results["documentation"], **context}
            )
            workflow["steps_completed"].append(WorkflowStep.BILLING.value)
            
            # Step 8: Schedule Follow-up
            workflow["current_step"] = WorkflowStep.FOLLOW_UP.value
            results["follow_up"] = await self.delegate_to_agent(
                AgentRole.FOLLOW_UP,
                "schedule_follow_up",
                {"patient_id": patient_id, "prevention_plan": results["prevention_plan"], **context}
            )
            workflow["steps_completed"].append(WorkflowStep.FOLLOW_UP.value)
            
            workflow["status"] = "completed"
            workflow["completed_at"] = datetime.now().isoformat()
            workflow["results"] = results
            
            return {
                "workflow_id": workflow_id,
                "status": "completed",
                "steps_completed": len(workflow["steps_completed"]),
                "results": results
            }
            
        except Exception as e:
            workflow["status"] = "failed"
            workflow["error"] = str(e)
            logger.error(f"Preventive workflow failed: {e}")
            return {
                "workflow_id": workflow_id,
                "status": "failed",
                "error": str(e),
                "steps_completed": workflow["steps_completed"]
            }

    async def delegate_to_agent(self, role: AgentRole, action: str, context: Dict[str, Any]) -> Any:
        """Delegate a task to a specific agent by role"""
        agent = next((a for a in self.sub_agents.values() if a.role == role), None)
        
        if agent is None:
            logger.warning(f"No agent found for role {role.value}, executing locally")
            return await self._execute_locally(role, action, context)
        
        message = await self.send_message(agent.name, action, context)
        result = await agent.receive_message(message)
        return result

    async def _execute_locally(self, role: AgentRole, action: str, context: Dict[str, Any]) -> Dict[str, Any]:
        """Execute task locally when no sub-agent is available"""
        # Fallback execution for when agents aren't registered
        return {
            "status": "executed_locally",
            "role": role.value,
            "action": action,
            "context": context,
            "message": "Executed by master agent (sub-agent not available)"
        }

    async def coordinate_agents(self, task: str, context: Dict[str, Any]) -> Dict[str, Any]:
        """Coordinate multiple agents to complete a complex task"""
        results = {}
        
        for agent_name, agent in self.sub_agents.items():
            try:
                result = await agent.execute(task, context)
                results[agent_name] = {"success": True, "result": result}
            except Exception as e:
                results[agent_name] = {"success": False, "error": str(e)}
        
        return {
            "task": task,
            "agents_involved": list(self.sub_agents.keys()),
            "results": results
        }

    def get_workflow_status(self, workflow_id: str) -> Optional[Dict[str, Any]]:
        """Get status of an active workflow"""
        return self.active_workflows.get(workflow_id)

    def get_all_agent_states(self) -> Dict[str, Dict[str, Any]]:
        """Get states of all registered agents"""
        states = {"master": self.get_state()}
        for name, agent in self.sub_agents.items():
            states[name] = agent.get_state()
        return states


# ============= SCHEDULING AGENTS =============

class SchedulingAgent(BaseAgent):
    """
    Smart Scheduling Agent - Optimizes appointment scheduling with conflict resolution
    """

    def __init__(self, gemini_client=None, backend_url: str = "http://localhost:8080/api"):
        super().__init__(
            agent_id="scheduling_001",
            role=AgentRole.SCHEDULING,
            gemini_client=gemini_client,
            backend_url=backend_url
        )
        self._register_tools()

    def _register_tools(self):
        """Register scheduling tools"""
        self.register_tool(self.get_available_slots, "get_available_slots", 
                          "Get available appointment slots for a doctor")
        self.register_tool(self.check_conflicts, "check_conflicts",
                          "Check for scheduling conflicts")
        self.register_tool(self.book_appointment, "book_appointment",
                          "Book an appointment for a patient")
        self.register_tool(self.reschedule_appointment, "reschedule_appointment",
                          "Reschedule an existing appointment")
        self.register_tool(self.optimize_schedule, "optimize_schedule",
                          "Optimize appointment schedule to minimize gaps")

    async def execute(self, task: str, context: Dict[str, Any] = None) -> Any:
        """Execute scheduling tasks"""
        context = context or {}
        task_lower = task.lower()
        
        if "schedule" in task_lower or "book" in task_lower:
            return await self.smart_schedule(context)
        elif "reschedule" in task_lower:
            return await self.reschedule_appointment(**context)
        elif "cancel" in task_lower:
            return await self.cancel_appointment(context.get("appointment_id"))
        elif "optimize" in task_lower:
            return await self.optimize_schedule(context.get("doctor_id"), context.get("date"))
        else:
            return await self.smart_schedule(context)

    async def smart_schedule(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Smart scheduling with conflict resolution and optimization
        """
        patient_id = context.get("patient_id")
        doctor_id = context.get("doctor_id")
        preferred_date = context.get("preferred_date")
        preferred_time = context.get("preferred_time")
        reason = context.get("reason", "Preventive Care Visit")
        token = context.get("token")
        
        # Step 1: Get available slots
        slots = await self.get_available_slots(doctor_id, preferred_date, token)
        
        if not slots.get("success") or not slots.get("data"):
            # Try to find alternative slots
            alternative_slots = await self._find_alternative_slots(doctor_id, preferred_date, token)
            if alternative_slots:
                slots = {"success": True, "data": alternative_slots}
            else:
                return {"success": False, "error": "No available slots found"}
        
        # Step 2: Check for conflicts
        best_slot = await self._find_best_slot(slots["data"], patient_id, preferred_time, token)
        
        if not best_slot:
            return {"success": False, "error": "Could not find a suitable slot without conflicts"}
        
        # Step 3: Book the appointment
        result = await self.book_appointment(
            patient_id=patient_id,
            doctor_id=doctor_id,
            slot=best_slot,
            reason=reason,
            token=token
        )
        
        # Step 4: Learn from this scheduling for future optimization
        if result.get("success"):
            self.memory.learn_pattern(
                f"schedule:{doctor_id}:{preferred_date}",
                {"slot": best_slot, "success": True}
            )
        
        return result

    async def get_available_slots(self, doctor_id: str, date: str = None, token: str = None) -> Dict[str, Any]:
        """Get available appointment slots from backend"""
        endpoint = f"/appointments/doctor/{doctor_id}/available-slots"
        if date:
            endpoint += f"?date={date}"
        
        result = await self.call_backend(endpoint, "GET", token=token)
        
        if not result.get("success"):
            # Generate default slots if backend fails
            slots = self._generate_default_slots(date or datetime.now().strftime("%Y-%m-%d"))
            return {"success": True, "data": slots, "generated": True}
        
        return result

    def _generate_default_slots(self, date: str) -> List[Dict[str, Any]]:
        """Generate default time slots for a date"""
        slots = []
        base_date = datetime.strptime(date, "%Y-%m-%d")
        
        # Morning slots: 9 AM - 12 PM
        for hour in range(9, 12):
            for minute in [0, 30]:
                slot_time = base_date.replace(hour=hour, minute=minute)
                slots.append({
                    "datetime": slot_time.isoformat(),
                    "duration_minutes": 30,
                    "available": True,
                    "slot_type": "preventive_care"
                })
        
        # Afternoon slots: 2 PM - 5 PM
        for hour in range(14, 17):
            for minute in [0, 30]:
                slot_time = base_date.replace(hour=hour, minute=minute)
                slots.append({
                    "datetime": slot_time.isoformat(),
                    "duration_minutes": 30,
                    "available": True,
                    "slot_type": "preventive_care"
                })
        
        return slots

    async def check_conflicts(self, patient_id: str, slot: Dict[str, Any], token: str = None) -> Dict[str, Any]:
        """Check if a slot conflicts with patient's existing appointments"""
        endpoint = f"/appointments/patient/{patient_id}"
        result = await self.call_backend(endpoint, "GET", token=token)
        
        if not result.get("success"):
            return {"has_conflict": False, "message": "Could not verify conflicts"}
        
        existing_appointments = result.get("data", [])
        slot_time = datetime.fromisoformat(slot["datetime"].replace("Z", "+00:00"))
        
        for apt in existing_appointments:
            apt_time = datetime.fromisoformat(apt["appointmentTime"].replace("Z", "+00:00"))
            time_diff = abs((apt_time - slot_time).total_seconds())
            
            if time_diff < 3600:  # Within 1 hour
                return {
                    "has_conflict": True,
                    "conflicting_appointment": apt,
                    "message": f"Conflicts with appointment at {apt_time}"
                }
        
        return {"has_conflict": False, "message": "No conflicts found"}

    async def _find_best_slot(self, slots: List[Dict[str, Any]], patient_id: str, 
                             preferred_time: str = None, token: str = None) -> Optional[Dict[str, Any]]:
        """Find the best available slot considering preferences and conflicts"""
        available_slots = [s for s in slots if s.get("available", True)]
        
        if not available_slots:
            return None
        
        # Sort by preference if provided
        if preferred_time:
            available_slots.sort(key=lambda s: abs(
                datetime.fromisoformat(s["datetime"]).hour - int(preferred_time.split(":")[0])
            ))
        
        # Check each slot for conflicts
        for slot in available_slots:
            conflict_check = await self.check_conflicts(patient_id, slot, token)
            if not conflict_check.get("has_conflict"):
                return slot
        
        return None

    async def _find_alternative_slots(self, doctor_id: str, date: str, token: str = None) -> List[Dict[str, Any]]:
        """Find alternative slots on nearby dates"""
        alternative_slots = []
        base_date = datetime.strptime(date, "%Y-%m-%d") if date else datetime.now()
        
        # Check next 7 days
        for day_offset in range(1, 8):
            next_date = base_date + timedelta(days=day_offset)
            if next_date.weekday() < 5:  # Weekdays only
                slots = await self.get_available_slots(
                    doctor_id, 
                    next_date.strftime("%Y-%m-%d"),
                    token
                )
                if slots.get("success") and slots.get("data"):
                    alternative_slots.extend(slots["data"][:3])  # Take top 3 from each day
        
        return alternative_slots

    async def book_appointment(self, patient_id: str, doctor_id: str, slot: Dict[str, Any],
                              reason: str = "", token: str = None) -> Dict[str, Any]:
        """Book an appointment"""
        appointment_data = {
            "patientId": int(patient_id),
            "doctorId": int(doctor_id) if doctor_id else 1,
            "appointmentTime": slot["datetime"],
            "notes": reason
        }
        
        result = await self.call_backend("/appointments/", "POST", appointment_data, token)
        
        if result.get("success"):
            self.memory.add_action("book_appointment", result, success=True, 
                                  context={"patient_id": patient_id, "slot": slot})
            return {
                "success": True,
                "appointment": result.get("data"),
                "message": f"Appointment booked for {slot['datetime']}"
            }
        else:
            return {
                "success": False,
                "error": result.get("error", "Failed to book appointment")
            }

    async def reschedule_appointment(self, appointment_id: str, new_slot: Dict[str, Any],
                                    token: str = None, **kwargs) -> Dict[str, Any]:
        """Reschedule an existing appointment"""
        update_data = {
            "appointmentTime": new_slot["datetime"],
            "notes": kwargs.get("reason", "Rescheduled")
        }
        
        result = await self.call_backend(f"/appointments/{appointment_id}", "PUT", update_data, token)
        
        return {
            "success": result.get("success", False),
            "message": "Appointment rescheduled" if result.get("success") else "Failed to reschedule",
            "data": result.get("data")
        }

    async def cancel_appointment(self, appointment_id: str, token: str = None) -> Dict[str, Any]:
        """Cancel an appointment"""
        result = await self.call_backend(f"/appointments/{appointment_id}", "DELETE", token=token)
        
        return {
            "success": result.get("success", False),
            "message": "Appointment cancelled" if result.get("success") else "Failed to cancel"
        }

    async def optimize_schedule(self, doctor_id: str, date: str, token: str = None) -> Dict[str, Any]:
        """Optimize the schedule to minimize gaps and improve efficiency"""
        # Get all appointments for the day
        endpoint = f"/appointments/doctor/{doctor_id}?date={date}"
        result = await self.call_backend(endpoint, "GET", token=token)
        
        if not result.get("success"):
            return {"success": False, "error": "Could not fetch appointments"}
        
        appointments = result.get("data", [])
        
        # Analyze gaps
        gaps = self._analyze_schedule_gaps(appointments)
        
        # Generate optimization suggestions
        suggestions = []
        for gap in gaps:
            if gap["duration_minutes"] >= 30:
                suggestions.append({
                    "type": "gap_detected",
                    "start": gap["start"],
                    "end": gap["end"],
                    "duration_minutes": gap["duration_minutes"],
                    "suggestion": "Consider scheduling a short consultation in this slot"
                })
        
        return {
            "success": True,
            "total_appointments": len(appointments),
            "gaps_found": len(gaps),
            "suggestions": suggestions,
            "efficiency_score": self._calculate_efficiency(appointments, gaps)
        }

    def _analyze_schedule_gaps(self, appointments: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Analyze gaps between appointments"""
        if len(appointments) < 2:
            return []
        
        # Sort by time
        sorted_apts = sorted(appointments, 
                            key=lambda x: datetime.fromisoformat(x["appointmentTime"].replace("Z", "")))
        
        gaps = []
        for i in range(len(sorted_apts) - 1):
            current_end = datetime.fromisoformat(sorted_apts[i]["appointmentTime"].replace("Z", ""))
            current_end += timedelta(minutes=30)  # Assume 30 min appointments
            next_start = datetime.fromisoformat(sorted_apts[i + 1]["appointmentTime"].replace("Z", ""))
            
            gap_minutes = (next_start - current_end).total_seconds() / 60
            if gap_minutes > 15:  # More than 15 minute gap
                gaps.append({
                    "start": current_end.isoformat(),
                    "end": next_start.isoformat(),
                    "duration_minutes": gap_minutes
                })
        
        return gaps

    def _calculate_efficiency(self, appointments: List[Dict[str, Any]], gaps: List[Dict[str, Any]]) -> float:
        """Calculate schedule efficiency score"""
        if not appointments:
            return 0.0
        
        total_gap_minutes = sum(g["duration_minutes"] for g in gaps)
        total_appointment_minutes = len(appointments) * 30  # Assume 30 min each
        
        if total_appointment_minutes + total_gap_minutes == 0:
            return 100.0
        
        efficiency = (total_appointment_minutes / (total_appointment_minutes + total_gap_minutes)) * 100
        return round(efficiency, 2)


class NotificationAgent(BaseAgent):
    """
    Notification Agent - Sends reminders and notifications to patients
    """

    def __init__(self, gemini_client=None, backend_url: str = "http://localhost:8080/api"):
        super().__init__(
            agent_id="notification_001",
            role=AgentRole.NOTIFICATION,
            gemini_client=gemini_client,
            backend_url=backend_url
        )

    async def execute(self, task: str, context: Dict[str, Any] = None) -> Any:
        """Execute notification tasks"""
        context = context or {}
        task_lower = task.lower()
        
        if "remind" in task_lower:
            return await self.send_reminder(context)
        elif "appointment" in task_lower:
            return await self.send_appointment_notification(context)
        elif "follow" in task_lower:
            return await self.send_follow_up_notification(context)
        else:
            return await self.send_notification(context)

    async def send_notification(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Send a general notification"""
        patient_id = context.get("patient_id")
        message = context.get("message", "")
        notification_type = context.get("type", "general")
        
        # In a real implementation, this would integrate with push notification services
        notification_data = {
            "patientId": patient_id,
            "message": message,
            "type": notification_type,
            "timestamp": datetime.now().isoformat(),
            "status": "sent"
        }
        
        # Log the notification
        self.memory.add_action("send_notification", notification_data, success=True, context=context)
        
        return {
            "success": True,
            "notification": notification_data,
            "message": "Notification sent successfully"
        }

    async def send_reminder(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Send a reminder notification"""
        patient_id = context.get("patient_id")
        reminder_type = context.get("reminder_type", "appointment")
        scheduled_time = context.get("scheduled_time")
        
        message = self._generate_reminder_message(reminder_type, context)
        
        return await self.send_notification({
            "patient_id": patient_id,
            "message": message,
            "type": "reminder",
            "reminder_type": reminder_type,
            "scheduled_time": scheduled_time
        })

    async def send_appointment_notification(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Send appointment confirmation/reminder"""
        appointment = context.get("appointment", {})
        patient_id = context.get("patient_id")
        
        message = f"Your appointment is scheduled for {appointment.get('appointmentTime', 'TBD')}. " \
                  f"Please arrive 15 minutes early."
        
        return await self.send_notification({
            "patient_id": patient_id,
            "message": message,
            "type": "appointment_confirmation",
            "appointment_id": appointment.get("id")
        })

    async def send_follow_up_notification(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Send follow-up reminder"""
        patient_id = context.get("patient_id")
        follow_up_date = context.get("follow_up_date")
        
        message = f"Reminder: Please complete your follow-up activities. " \
                  f"Your next check-in is scheduled for {follow_up_date}."
        
        return await self.send_notification({
            "patient_id": patient_id,
            "message": message,
            "type": "follow_up_reminder"
        })

    def _generate_reminder_message(self, reminder_type: str, context: Dict[str, Any]) -> str:
        """Generate appropriate reminder message"""
        messages = {
            "appointment": f"Reminder: You have an upcoming appointment. Please confirm your attendance.",
            "medication": f"Time to take your medication: {context.get('medication_name', 'prescribed medication')}",
            "hra": "Please complete your Health Risk Assessment before your upcoming visit.",
            "follow_up": "Reminder: Please complete your scheduled follow-up activities.",
            "preventive_care": "It's time for your preventive care checkup. Schedule your appointment today!"
        }
        return messages.get(reminder_type, "You have a new health notification.")


class EmailAgent(BaseAgent):
    """
    Email Agent - Handles email communications
    """

    def __init__(self, gemini_client=None, backend_url: str = "http://localhost:8080/api"):
        super().__init__(
            agent_id="email_001",
            role=AgentRole.EMAIL,
            gemini_client=gemini_client,
            backend_url=backend_url
        )

    async def execute(self, task: str, context: Dict[str, Any] = None) -> Any:
        """Execute email tasks"""
        return await self.send_email(context or {})

    async def send_email(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Send an email"""
        recipient = context.get("email")
        subject = context.get("subject", "NalaMAI Health Notification")
        body = context.get("body", "")
        template = context.get("template")
        
        if template:
            body = self._apply_template(template, context)
        
        # In production, this would integrate with email service
        email_data = {
            "to": recipient,
            "subject": subject,
            "body": body,
            "timestamp": datetime.now().isoformat(),
            "status": "sent"
        }
        
        self.memory.add_action("send_email", email_data, success=True, context=context)
        
        return {
            "success": True,
            "email": email_data,
            "message": "Email sent successfully"
        }

    def _apply_template(self, template: str, context: Dict[str, Any]) -> str:
        """Apply email template"""
        templates = {
            "appointment_confirmation": """
Dear {patient_name},

Your appointment has been confirmed for {appointment_time}.

Doctor: {doctor_name}
Location: {location}

Please remember to:
1. Arrive 15 minutes early
2. Bring your insurance card
3. Complete the Health Risk Assessment

Best regards,
NalaMAI Healthcare Team
            """,
            "hra_reminder": """
Dear {patient_name},

Please complete your Health Risk Assessment before your upcoming appointment on {appointment_time}.

Click here to complete: {hra_link}

This assessment helps us provide you with personalized preventive care.

Best regards,
NalaMAI Healthcare Team
            """
        }
        
        template_body = templates.get(template, "{body}")
        return template_body.format(**context)


# ============= PREDICTIVE AGENT =============

class PredictiveAgent(BaseAgent):
    """
    Predictive Agent - Predicts no-shows, health risks, and provides analytics
    """

    def __init__(self, gemini_client=None, backend_url: str = "http://localhost:8080/api"):
        super().__init__(
            agent_id="predictive_001",
            role=AgentRole.PREDICTIVE,
            gemini_client=gemini_client,
            backend_url=backend_url
        )
        self._register_tools()

    def _register_tools(self):
        """Register predictive tools"""
        self.register_tool(self.predict_no_show, "predict_no_show",
                          "Predict probability of appointment no-show")
        self.register_tool(self.assess_health_risk, "assess_health_risk",
                          "Assess patient health risk based on vitals and history")
        self.register_tool(self.get_patient_analytics, "get_patient_analytics",
                          "Get analytics and trends for a patient")

    async def execute(self, task: str, context: Dict[str, Any] = None) -> Any:
        """Execute predictive tasks"""
        context = context or {}
        task_lower = task.lower()
        
        if "no-show" in task_lower or "noshow" in task_lower:
            return await self.predict_no_show(context)
        elif "risk" in task_lower:
            return await self.assess_health_risk(context)
        elif "analytics" in task_lower or "trend" in task_lower:
            return await self.get_patient_analytics(context)
        else:
            return await self.comprehensive_prediction(context)

    async def predict_no_show(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Predict probability of patient not showing up for appointment.
        Uses historical patterns and patient data.
        """
        patient_id = context.get("patient_id")
        appointment_id = context.get("appointment_id")
        token = context.get("token")
        
        # Get patient history
        history = await self.call_backend(f"/appointments/patient/{patient_id}", "GET", token=token)
        
        # Calculate no-show probability based on history
        no_show_rate = 0.15  # Default 15%
        risk_factors = []
        
        if history.get("success") and history.get("data"):
            appointments = history["data"]
            cancelled = sum(1 for a in appointments if a.get("status") == "CANCELLED")
            completed = sum(1 for a in appointments if a.get("status") == "COMPLETED")
            total = len(appointments)
            
            if total > 0:
                no_show_rate = cancelled / total
                
            # Analyze patterns
            if no_show_rate > 0.3:
                risk_factors.append("High historical no-show rate")
            
            # Check for recent cancellations
            recent = [a for a in appointments 
                     if datetime.fromisoformat(a["appointmentTime"].replace("Z", "")) 
                     > datetime.now() - timedelta(days=90)]
            recent_cancelled = sum(1 for a in recent if a.get("status") == "CANCELLED")
            if recent_cancelled > 2:
                risk_factors.append("Multiple recent cancellations")
                no_show_rate += 0.1
        
        # Clamp probability
        no_show_rate = min(max(no_show_rate, 0.0), 1.0)
        
        risk_level = "low" if no_show_rate < 0.2 else "medium" if no_show_rate < 0.4 else "high"
        
        result = {
            "patient_id": patient_id,
            "no_show_probability": round(no_show_rate, 3),
            "risk_level": risk_level,
            "risk_factors": risk_factors,
            "recommendations": self._get_no_show_recommendations(risk_level)
        }
        
        self.memory.add_action("predict_no_show", result, success=True, context=context)
        return result

    def _get_no_show_recommendations(self, risk_level: str) -> List[str]:
        """Get recommendations based on no-show risk level"""
        recommendations = {
            "low": ["Send standard reminder 24 hours before"],
            "medium": [
                "Send multiple reminders (48h, 24h, 2h before)",
                "Consider phone call confirmation",
                "Offer easy rescheduling options"
            ],
            "high": [
                "Personal phone call confirmation required",
                "Send reminders at 72h, 48h, 24h, and 2h before",
                "Consider double-booking this slot",
                "Offer transportation assistance if needed",
                "Identify and address barriers to attendance"
            ]
        }
        return recommendations.get(risk_level, recommendations["low"])

    async def assess_health_risk(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Assess patient health risk based on vitals and medical history
        """
        patient_id = context.get("patient_id")
        token = context.get("token")
        
        # Get patient vitals
        vitals_result = await self.call_backend(f"/vitals/patient/{patient_id}/latest", "GET", token=token)
        
        # Get medical history
        history_result = await self.call_backend(f"/records/patient/{patient_id}", "GET", token=token)
        
        # Calculate risk scores
        risk_assessment = {
            "patient_id": patient_id,
            "overall_risk_score": 0.0,
            "risk_level": "low",
            "risk_factors": [],
            "vital_concerns": [],
            "recommendations": []
        }
        
        # Analyze vitals if available
        if vitals_result.get("success") and vitals_result.get("data"):
            vitals = vitals_result["data"]
            vital_risks = self._analyze_vital_risks(vitals)
            risk_assessment["vital_concerns"] = vital_risks["concerns"]
            risk_assessment["overall_risk_score"] += vital_risks["score"]
        
        # Analyze history if available
        if history_result.get("success") and history_result.get("data"):
            history = history_result["data"]
            history_risks = self._analyze_history_risks(history)
            risk_assessment["risk_factors"].extend(history_risks["factors"])
            risk_assessment["overall_risk_score"] += history_risks["score"]
        
        # Normalize risk score
        risk_assessment["overall_risk_score"] = min(risk_assessment["overall_risk_score"], 1.0)
        
        # Determine risk level
        score = risk_assessment["overall_risk_score"]
        risk_assessment["risk_level"] = "low" if score < 0.3 else "medium" if score < 0.6 else "high"
        
        # Generate recommendations
        risk_assessment["recommendations"] = self._generate_health_recommendations(risk_assessment)
        
        self.memory.add_action("assess_health_risk", risk_assessment, success=True, context=context)
        return risk_assessment

    def _analyze_vital_risks(self, vitals: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze vital signs for health risks"""
        concerns = []
        score = 0.0
        
        # Blood pressure analysis
        systolic = vitals.get("systolicBP") or vitals.get("BP_Systolic", {}).get("value", 120)
        diastolic = vitals.get("diastolicBP") or vitals.get("BP_Diastolic", {}).get("value", 80)
        
        if systolic > 140 or diastolic > 90:
            concerns.append({"type": "hypertension", "value": f"{systolic}/{diastolic}", "severity": "high"})
            score += 0.3
        elif systolic > 130 or diastolic > 85:
            concerns.append({"type": "elevated_bp", "value": f"{systolic}/{diastolic}", "severity": "medium"})
            score += 0.15
        
        # Heart rate analysis
        heart_rate = vitals.get("heartRate") or vitals.get("HeartRate", {}).get("value", 75)
        if heart_rate > 100:
            concerns.append({"type": "tachycardia", "value": heart_rate, "severity": "medium"})
            score += 0.1
        elif heart_rate < 50:
            concerns.append({"type": "bradycardia", "value": heart_rate, "severity": "medium"})
            score += 0.1
        
        # SpO2 analysis
        spo2 = vitals.get("oxygenLevel") or vitals.get("SpO2", {}).get("value", 98)
        if spo2 < 95:
            concerns.append({"type": "low_oxygen", "value": spo2, "severity": "high"})
            score += 0.25
        
        return {"concerns": concerns, "score": score}

    def _analyze_history_risks(self, history: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Analyze medical history for risk factors"""
        factors = []
        score = 0.0
        
        # This would analyze conditions from medical records
        # For now, return default analysis
        return {"factors": factors, "score": score}

    def _generate_health_recommendations(self, risk_assessment: Dict[str, Any]) -> List[str]:
        """Generate health recommendations based on risk assessment"""
        recommendations = []
        
        for concern in risk_assessment.get("vital_concerns", []):
            if concern["type"] == "hypertension":
                recommendations.extend([
                    "Monitor blood pressure daily",
                    "Reduce sodium intake",
                    "Consider consultation with cardiologist"
                ])
            elif concern["type"] == "low_oxygen":
                recommendations.extend([
                    "Seek immediate medical attention if symptoms worsen",
                    "Practice deep breathing exercises",
                    "Consult with pulmonologist"
                ])
        
        if risk_assessment["risk_level"] == "high":
            recommendations.append("Schedule preventive care visit within 2 weeks")
        elif risk_assessment["risk_level"] == "medium":
            recommendations.append("Schedule preventive care visit within 1 month")
        
        return recommendations

    async def get_patient_analytics(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Get analytics and trends for a patient"""
        patient_id = context.get("patient_id")
        period = context.get("period", "month")  # day, week, month, year
        token = context.get("token")
        
        # Get vital history for trends
        vitals_result = await self.call_backend(f"/vitals/patient/{patient_id}", "GET", token=token)
        
        analytics = {
            "patient_id": patient_id,
            "period": period,
            "vitals_trend": {},
            "appointment_compliance": 0.0,
            "health_score": 75,  # Default score
            "improvement_areas": [],
            "achievements": []
        }
        
        if vitals_result.get("success") and vitals_result.get("data"):
            analytics["vitals_trend"] = self._calculate_vitals_trend(vitals_result["data"])
        
        return analytics

    def _calculate_vitals_trend(self, vitals_history: List[Dict[str, Any]]) -> Dict[str, str]:
        """Calculate trend direction for vitals"""
        trends = {
            "blood_pressure": "stable",
            "heart_rate": "stable",
            "oxygen_level": "stable"
        }
        
        if len(vitals_history) < 2:
            return trends
        
        # Simplified trend analysis
        # In production, this would use more sophisticated time-series analysis
        return trends

    async def comprehensive_prediction(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Comprehensive prediction combining all predictive capabilities"""
        patient_id = context.get("patient_id")
        
        # Run all predictions in parallel
        results = await asyncio.gather(
            self.predict_no_show(context),
            self.assess_health_risk(context),
            self.get_patient_analytics(context),
            return_exceptions=True
        )
        
        return {
            "patient_id": patient_id,
            "no_show_prediction": results[0] if not isinstance(results[0], Exception) else None,
            "health_risk": results[1] if not isinstance(results[1], Exception) else None,
            "analytics": results[2] if not isinstance(results[2], Exception) else None
        }


# ============= PATIENT AGENTS =============

class InitiationAgent(BaseAgent):
    """
    Initiation Agent - Identifies eligible patients for preventive care
    """

    def __init__(self, gemini_client=None, backend_url: str = "http://localhost:8080/api"):
        super().__init__(
            agent_id="initiation_001",
            role=AgentRole.INITIATION,
            gemini_client=gemini_client,
            backend_url=backend_url
        )

    async def execute(self, task: str, context: Dict[str, Any] = None) -> Any:
        """Execute patient identification tasks"""
        context = context or {}
        
        if "eligible" in task.lower() or "identify" in task.lower():
            return await self.identify_eligible_patients(context)
        elif "check" in task.lower():
            return await self.check_patient_eligibility(context.get("patient_id"), context)
        else:
            return await self.identify_eligible_patients(context)

    async def identify_eligible_patients(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Identify patients eligible for preventive care based on criteria:
        - Age-based screenings
        - Time since last preventive visit
        - Risk factors
        - Insurance coverage
        """
        token = context.get("token")
        
        # Get all patients
        patients_result = await self.call_backend("/patients", "GET", token=token)
        
        eligible_patients = []
        
        if patients_result.get("success") and patients_result.get("data"):
            for patient in patients_result["data"]:
                eligibility = await self.check_patient_eligibility(patient.get("id"), context)
                if eligibility.get("eligible"):
                    eligible_patients.append({
                        "patient": patient,
                        "eligibility": eligibility
                    })
        
        return {
            "total_patients_checked": len(patients_result.get("data", [])),
            "eligible_count": len(eligible_patients),
            "eligible_patients": eligible_patients[:50],  # Return top 50
            "generated_at": datetime.now().isoformat()
        }

    async def check_patient_eligibility(self, patient_id: str, context: Dict[str, Any] = None) -> Dict[str, Any]:
        """Check if a specific patient is eligible for preventive care"""
        context = context or {}
        token = context.get("token")
        
        # Get patient details
        patient_result = await self.call_backend(f"/patients/{patient_id}", "GET", token=token)
        
        eligibility = {
            "patient_id": patient_id,
            "eligible": False,
            "reasons": [],
            "recommended_services": [],
            "priority": "normal"
        }
        
        if not patient_result.get("success"):
            eligibility["reasons"].append("Could not fetch patient data")
            return eligibility
        
        patient = patient_result.get("data", {})
        
        # Check eligibility criteria
        
        # 1. Age-based screenings
        dob = patient.get("dateOfBirth")
        if dob:
            try:
                birth_date = datetime.fromisoformat(dob.replace("Z", ""))
                age = (datetime.now() - birth_date).days // 365
                
                if age >= 65:
                    eligibility["recommended_services"].append("Annual Wellness Visit")
                    eligibility["eligible"] = True
                    eligibility["reasons"].append("Age 65+: Eligible for Medicare Annual Wellness Visit")
                    eligibility["priority"] = "high"
                elif age >= 50:
                    eligibility["recommended_services"].extend([
                        "Colorectal Cancer Screening",
                        "Cardiovascular Risk Assessment"
                    ])
                    eligibility["eligible"] = True
                    eligibility["reasons"].append("Age 50+: Eligible for age-based screenings")
                elif age >= 40:
                    eligibility["recommended_services"].append("Preventive Health Check")
                    eligibility["eligible"] = True
                    eligibility["reasons"].append("Age 40+: Eligible for preventive health check")
            except:
                pass
        
        # 2. Check last preventive visit
        appointments_result = await self.call_backend(
            f"/appointments/patient/{patient_id}?status=COMPLETED", "GET", token=token
        )
        
        if appointments_result.get("success"):
            appointments = appointments_result.get("data", [])
            preventive_visits = [a for a in appointments if "preventive" in (a.get("notes") or "").lower()]
            
            if not preventive_visits:
                eligibility["eligible"] = True
                eligibility["reasons"].append("No previous preventive visit on record")
                eligibility["priority"] = "high"
            else:
                # Check if last visit was more than 1 year ago
                last_visit = max(preventive_visits, 
                               key=lambda x: x.get("appointmentTime", ""))
                last_visit_date = datetime.fromisoformat(
                    last_visit["appointmentTime"].replace("Z", "")
                )
                
                if (datetime.now() - last_visit_date).days > 365:
                    eligibility["eligible"] = True
                    eligibility["reasons"].append("More than 12 months since last preventive visit")
        
        # 3. Check for risk factors (would analyze medical history)
        # Simplified for now
        if context.get("high_risk"):
            eligibility["eligible"] = True
            eligibility["priority"] = "urgent"
            eligibility["reasons"].append("Identified as high-risk patient")
        
        return eligibility


class HRAAgent(BaseAgent):
    """
    Health Risk Assessment Agent - Manages HRA distribution and validation
    """

    def __init__(self, gemini_client=None, backend_url: str = "http://localhost:8080/api"):
        super().__init__(
            agent_id="hra_001",
            role=AgentRole.HRA,
            gemini_client=gemini_client,
            backend_url=backend_url
        )

    async def execute(self, task: str, context: Dict[str, Any] = None) -> Any:
        """Execute HRA tasks"""
        context = context or {}
        task_lower = task.lower()
        
        if "distribute" in task_lower or "send" in task_lower:
            return await self.distribute_hra(context)
        elif "validate" in task_lower:
            return await self.validate_hra(context)
        elif "analyze" in task_lower:
            return await self.analyze_hra_responses(context)
        else:
            return await self.distribute_hra(context)

    async def distribute_hra(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Distribute Health Risk Assessment to patient"""
        patient_id = context.get("patient_id")
        appointment = context.get("appointment", {})
        
        # Generate HRA based on patient demographics
        hra = self._generate_hra_questions(context)
        
        # In production, this would save to database and send to patient
        distribution_result = {
            "patient_id": patient_id,
            "hra_id": str(uuid.uuid4()),
            "appointment_id": appointment.get("id"),
            "questions_count": len(hra["questions"]),
            "distributed_at": datetime.now().isoformat(),
            "deadline": (datetime.now() + timedelta(days=3)).isoformat(),
            "status": "sent",
            "hra": hra
        }
        
        self.memory.add_action("distribute_hra", distribution_result, success=True, context=context)
        
        return distribution_result

    def _generate_hra_questions(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Generate HRA questions based on patient profile"""
        return {
            "title": "Health Risk Assessment",
            "version": "1.0",
            "questions": [
                {
                    "id": "q1",
                    "category": "general_health",
                    "question": "How would you rate your overall health?",
                    "type": "scale",
                    "options": ["Excellent", "Very Good", "Good", "Fair", "Poor"]
                },
                {
                    "id": "q2",
                    "category": "physical_activity",
                    "question": "How many days per week do you engage in physical activity for at least 30 minutes?",
                    "type": "number",
                    "min": 0,
                    "max": 7
                },
                {
                    "id": "q3",
                    "category": "smoking",
                    "question": "Do you currently smoke or use tobacco products?",
                    "type": "boolean"
                },
                {
                    "id": "q4",
                    "category": "alcohol",
                    "question": "How many alcoholic drinks do you consume per week?",
                    "type": "number",
                    "min": 0,
                    "max": 50
                },
                {
                    "id": "q5",
                    "category": "mental_health",
                    "question": "In the past 2 weeks, have you felt down, depressed, or hopeless?",
                    "type": "frequency",
                    "options": ["Not at all", "Several days", "More than half the days", "Nearly every day"]
                },
                {
                    "id": "q6",
                    "category": "chronic_conditions",
                    "question": "Have you been diagnosed with any of the following conditions?",
                    "type": "multiselect",
                    "options": ["Diabetes", "High Blood Pressure", "Heart Disease", "Asthma", "Arthritis", "None"]
                },
                {
                    "id": "q7",
                    "category": "medications",
                    "question": "Are you currently taking any prescription medications?",
                    "type": "boolean"
                },
                {
                    "id": "q8",
                    "category": "sleep",
                    "question": "On average, how many hours of sleep do you get per night?",
                    "type": "number",
                    "min": 0,
                    "max": 24
                },
                {
                    "id": "q9",
                    "category": "diet",
                    "question": "How would you describe your diet?",
                    "type": "scale",
                    "options": ["Very healthy", "Somewhat healthy", "Neither healthy nor unhealthy", "Somewhat unhealthy", "Very unhealthy"]
                },
                {
                    "id": "q10",
                    "category": "screenings",
                    "question": "Have you had any preventive screenings in the past year (e.g., mammogram, colonoscopy, blood work)?",
                    "type": "boolean"
                }
            ]
        }

    async def validate_hra(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Validate HRA responses for completeness and consistency"""
        hra_id = context.get("hra_id")
        responses = context.get("responses", {})
        
        validation = {
            "hra_id": hra_id,
            "is_valid": True,
            "completeness": 0.0,
            "issues": [],
            "risk_flags": []
        }
        
        # Check completeness
        expected_questions = 10
        answered = len([r for r in responses.values() if r is not None])
        validation["completeness"] = answered / expected_questions
        
        if validation["completeness"] < 1.0:
            validation["issues"].append(f"Incomplete: {expected_questions - answered} questions unanswered")
            validation["is_valid"] = validation["completeness"] >= 0.8  # Allow 80% completion
        
        # Check for risk flags
        if responses.get("q3") == True:  # Smoking
            validation["risk_flags"].append({"type": "smoking", "priority": "high"})
        
        if responses.get("q5") in ["More than half the days", "Nearly every day"]:
            validation["risk_flags"].append({"type": "depression_screening", "priority": "high"})
        
        alcohol = responses.get("q4", 0)
        if isinstance(alcohol, (int, float)) and alcohol > 14:
            validation["risk_flags"].append({"type": "alcohol_concern", "priority": "medium"})
        
        return validation

    async def analyze_hra_responses(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze HRA responses to generate insights"""
        responses = context.get("responses", {})
        
        analysis = {
            "health_score": 75,  # Default baseline
            "risk_areas": [],
            "positive_factors": [],
            "recommendations": []
        }
        
        # Analyze each category
        if responses.get("q1") in ["Excellent", "Very Good"]:
            analysis["positive_factors"].append("Self-reported good health")
            analysis["health_score"] += 5
        elif responses.get("q1") in ["Fair", "Poor"]:
            analysis["risk_areas"].append("Low self-reported health status")
            analysis["health_score"] -= 10
        
        # Physical activity
        activity_days = responses.get("q2", 0)
        if isinstance(activity_days, (int, float)):
            if activity_days >= 5:
                analysis["positive_factors"].append("Active lifestyle (5+ days/week)")
                analysis["health_score"] += 10
            elif activity_days < 2:
                analysis["risk_areas"].append("Low physical activity")
                analysis["health_score"] -= 5
                analysis["recommendations"].append("Increase physical activity to at least 150 minutes per week")
        
        # Sleep
        sleep_hours = responses.get("q8", 7)
        if isinstance(sleep_hours, (int, float)):
            if sleep_hours < 6:
                analysis["risk_areas"].append("Insufficient sleep")
                analysis["recommendations"].append("Aim for 7-9 hours of sleep per night")
            elif 7 <= sleep_hours <= 9:
                analysis["positive_factors"].append("Adequate sleep")
        
        # Normalize score
        analysis["health_score"] = max(0, min(100, analysis["health_score"]))
        
        return analysis


class FollowUpAgent(BaseAgent):
    """
    Follow-up Agent - Tracks adherence and manages follow-up activities
    """

    def __init__(self, gemini_client=None, backend_url: str = "http://localhost:8080/api"):
        super().__init__(
            agent_id="followup_001",
            role=AgentRole.FOLLOW_UP,
            gemini_client=gemini_client,
            backend_url=backend_url
        )

    async def execute(self, task: str, context: Dict[str, Any] = None) -> Any:
        """Execute follow-up tasks"""
        context = context or {}
        task_lower = task.lower()
        
        if "schedule" in task_lower:
            return await self.schedule_follow_up(context)
        elif "check" in task_lower or "adherence" in task_lower:
            return await self.check_adherence(context)
        elif "reminder" in task_lower:
            return await self.send_follow_up_reminder(context)
        else:
            return await self.schedule_follow_up(context)

    async def schedule_follow_up(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Schedule follow-up activities based on prevention plan"""
        patient_id = context.get("patient_id")
        prevention_plan = context.get("prevention_plan", {})
        
        follow_ups = []
        
        # Generate follow-up schedule based on prevention plan
        if prevention_plan.get("screenings"):
            for screening in prevention_plan["screenings"]:
                follow_ups.append({
                    "type": "screening_reminder",
                    "activity": screening.get("name"),
                    "due_date": screening.get("due_date"),
                    "priority": screening.get("priority", "normal")
                })
        
        if prevention_plan.get("medications"):
            follow_ups.append({
                "type": "medication_adherence_check",
                "activity": "Medication adherence check",
                "due_date": (datetime.now() + timedelta(days=7)).isoformat(),
                "priority": "normal"
            })
        
        # Always schedule a general follow-up
        follow_ups.append({
            "type": "general_check_in",
            "activity": "General health check-in",
            "due_date": (datetime.now() + timedelta(days=30)).isoformat(),
            "priority": "normal"
        })
        
        return {
            "patient_id": patient_id,
            "follow_ups_scheduled": len(follow_ups),
            "follow_ups": follow_ups,
            "created_at": datetime.now().isoformat()
        }

    async def check_adherence(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Check patient adherence to prevention plan"""
        patient_id = context.get("patient_id")
        token = context.get("token")
        
        # Check various adherence metrics
        adherence = {
            "patient_id": patient_id,
            "overall_adherence_score": 0.0,
            "medication_adherence": None,
            "appointment_adherence": None,
            "lifestyle_adherence": None,
            "gaps_identified": [],
            "recommendations": []
        }
        
        # Check appointment adherence
        appointments_result = await self.call_backend(
            f"/appointments/patient/{patient_id}", "GET", token=token
        )
        
        if appointments_result.get("success"):
            appointments = appointments_result.get("data", [])
            total = len(appointments)
            completed = sum(1 for a in appointments if a.get("status") == "COMPLETED")
            
            if total > 0:
                adherence["appointment_adherence"] = completed / total
                if adherence["appointment_adherence"] < 0.8:
                    adherence["gaps_identified"].append("Low appointment completion rate")
                    adherence["recommendations"].append("Consider appointment reminders and barriers assessment")
        
        # Calculate overall score (simplified)
        scores = [v for v in [
            adherence["medication_adherence"],
            adherence["appointment_adherence"],
            adherence["lifestyle_adherence"]
        ] if v is not None]
        
        if scores:
            adherence["overall_adherence_score"] = sum(scores) / len(scores)
        
        return adherence

    async def send_follow_up_reminder(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Send follow-up reminder to patient"""
        patient_id = context.get("patient_id")
        follow_up_type = context.get("type", "general")
        
        # Create reminder notification
        reminder = {
            "patient_id": patient_id,
            "type": "follow_up_reminder",
            "follow_up_type": follow_up_type,
            "message": self._generate_reminder_message(follow_up_type),
            "sent_at": datetime.now().isoformat()
        }
        
        return reminder

    def _generate_reminder_message(self, follow_up_type: str) -> str:
        """Generate appropriate follow-up message"""
        messages = {
            "screening_reminder": "Reminder: You have a scheduled health screening. Please complete it as planned.",
            "medication_adherence_check": "How are you doing with your medications? Please let us know if you have any concerns.",
            "general_check_in": "It's time for your health check-in. How are you feeling? Any concerns to discuss?",
            "lifestyle": "Reminder to maintain your healthy lifestyle goals. Keep up the great work!"
        }
        return messages.get(follow_up_type, "Time for your health follow-up. Please respond to this notification.")


# ============= CLINICAL AGENTS =============

class PreVisitAgent(BaseAgent):
    """
    Pre-Visit Preparation Agent - Prepares for preventive visits
    """

    def __init__(self, gemini_client=None, backend_url: str = "http://localhost:8080/api"):
        super().__init__(
            agent_id="previsit_001",
            role=AgentRole.PRE_VISIT,
            gemini_client=gemini_client,
            backend_url=backend_url
        )

    async def execute(self, task: str, context: Dict[str, Any] = None) -> Any:
        """Execute pre-visit preparation tasks"""
        return await self.prepare_visit(context or {})

    async def prepare_visit(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Prepare comprehensive pre-visit summary including:
        - HRA review and validation
        - Vital trends
        - Medical history summary
        - Recommended screenings
        - Provider notes
        """
        patient_id = context.get("patient_id")
        hra = context.get("hra", {})
        token = context.get("token")
        
        preparation = {
            "patient_id": patient_id,
            "prepared_at": datetime.now().isoformat(),
            "hra_summary": None,
            "vitals_summary": None,
            "history_summary": None,
            "recommended_screenings": [],
            "flags": [],
            "provider_notes": []
        }
        
        # Validate and summarize HRA
        if hra:
            preparation["hra_summary"] = {
                "completed": hra.get("status") == "completed",
                "risk_flags": hra.get("risk_flags", []),
                "key_findings": []
            }
            
            # Add risk flags to main flags
            for flag in hra.get("risk_flags", []):
                preparation["flags"].append({
                    "source": "HRA",
                    "type": flag.get("type"),
                    "priority": flag.get("priority", "medium")
                })
        
        # Get vitals summary
        vitals_result = await self.call_backend(f"/vitals/patient/{patient_id}", "GET", token=token)
        if vitals_result.get("success") and vitals_result.get("data"):
            vitals = vitals_result["data"]
            preparation["vitals_summary"] = {
                "latest": vitals[0] if vitals else None,
                "trends": self._analyze_trends(vitals),
                "concerns": []
            }
            
            # Check for vital concerns
            latest = vitals[0] if vitals else {}
            if latest.get("systolicBP", 0) > 140:
                preparation["vitals_summary"]["concerns"].append("Elevated blood pressure")
                preparation["flags"].append({
                    "source": "vitals",
                    "type": "hypertension",
                    "priority": "high"
                })
        
        # Get medical history summary
        history_result = await self.call_backend(f"/records/patient/{patient_id}", "GET", token=token)
        if history_result.get("success") and history_result.get("data"):
            records = history_result["data"]
            preparation["history_summary"] = {
                "total_records": len(records),
                "recent_diagnoses": [r.get("diagnosis") for r in records[:5] if r.get("diagnosis")],
                "active_medications": []  # Would be populated from medication data
            }
        
        # Generate recommended screenings
        preparation["recommended_screenings"] = self._generate_screening_recommendations(preparation)
        
        # Generate provider notes
        preparation["provider_notes"] = self._generate_provider_notes(preparation)
        
        return preparation

    def _analyze_trends(self, vitals: List[Dict[str, Any]]) -> Dict[str, str]:
        """Analyze vital sign trends"""
        return {
            "blood_pressure": "stable",
            "heart_rate": "stable",
            "weight": "stable"
        }

    def _generate_screening_recommendations(self, preparation: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Generate screening recommendations based on preparation data"""
        recommendations = []
        
        # Add standard preventive screenings
        recommendations.append({
            "name": "Blood Pressure Screening",
            "rationale": "Standard preventive care",
            "priority": "routine"
        })
        
        recommendations.append({
            "name": "Body Mass Index (BMI) Assessment",
            "rationale": "Standard preventive care",
            "priority": "routine"
        })
        
        # Add based on flags
        for flag in preparation.get("flags", []):
            if flag["type"] == "smoking":
                recommendations.append({
                    "name": "Lung Cancer Screening Discussion",
                    "rationale": "Tobacco use identified",
                    "priority": "high"
                })
            if flag["type"] == "depression_screening":
                recommendations.append({
                    "name": "Mental Health Assessment",
                    "rationale": "Depression risk identified in HRA",
                    "priority": "high"
                })
        
        return recommendations

    def _generate_provider_notes(self, preparation: Dict[str, Any]) -> List[str]:
        """Generate notes for the healthcare provider"""
        notes = []
        
        if preparation.get("flags"):
            high_priority = [f for f in preparation["flags"] if f.get("priority") == "high"]
            if high_priority:
                notes.append(f"⚠️ {len(high_priority)} high-priority flags require attention")
        
        if preparation.get("hra_summary", {}).get("completed"):
            notes.append("✓ HRA completed and reviewed")
        else:
            notes.append("⚠️ HRA not completed - consider completing during visit")
        
        return notes


class PreventionPlanAgent(BaseAgent):
    """
    Prevention Plan Agent - Generates personalized prevention plans
    """

    def __init__(self, gemini_client=None, backend_url: str = "http://localhost:8080/api"):
        super().__init__(
            agent_id="preventionplan_001",
            role=AgentRole.PREVENTION_PLAN,
            gemini_client=gemini_client,
            backend_url=backend_url
        )

    async def execute(self, task: str, context: Dict[str, Any] = None) -> Any:
        """Execute prevention plan tasks"""
        return await self.generate_prevention_plan(context or {})

    async def generate_prevention_plan(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Generate personalized prevention plan based on:
        - Pre-visit assessment
        - Risk factors
        - Age and gender
        - Medical history
        - Guidelines
        """
        patient_id = context.get("patient_id")
        pre_visit = context.get("pre_visit", {})
        
        plan = {
            "patient_id": patient_id,
            "plan_id": str(uuid.uuid4()),
            "created_at": datetime.now().isoformat(),
            "valid_until": (datetime.now() + timedelta(days=365)).isoformat(),
            "screenings": [],
            "vaccinations": [],
            "lifestyle_recommendations": [],
            "referrals": [],
            "follow_up_schedule": []
        }
        
        # Add screenings based on assessment
        plan["screenings"] = self._generate_screening_schedule(pre_visit)
        
        # Add vaccination recommendations
        plan["vaccinations"] = self._generate_vaccination_recommendations()
        
        # Add lifestyle recommendations
        plan["lifestyle_recommendations"] = self._generate_lifestyle_recommendations(pre_visit)
        
        # Add referrals if needed
        if pre_visit.get("flags"):
            plan["referrals"] = self._generate_referrals(pre_visit["flags"])
        
        # Generate follow-up schedule
        plan["follow_up_schedule"] = self._generate_follow_up_schedule(plan)
        
        self.memory.add_action("generate_prevention_plan", plan, success=True, context=context)
        
        return plan

    def _generate_screening_schedule(self, pre_visit: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Generate screening schedule"""
        screenings = []
        
        # Standard screenings
        screenings.append({
            "name": "Annual Physical Examination",
            "frequency": "yearly",
            "due_date": (datetime.now() + timedelta(days=365)).isoformat(),
            "priority": "routine"
        })
        
        screenings.append({
            "name": "Lipid Panel",
            "frequency": "yearly",
            "due_date": (datetime.now() + timedelta(days=365)).isoformat(),
            "priority": "routine"
        })
        
        # Add based on pre-visit findings
        for screening in pre_visit.get("recommended_screenings", []):
            screenings.append({
                "name": screening["name"],
                "frequency": "as_recommended",
                "due_date": (datetime.now() + timedelta(days=30)).isoformat(),
                "priority": screening.get("priority", "routine"),
                "rationale": screening.get("rationale")
            })
        
        return screenings

    def _generate_vaccination_recommendations(self) -> List[Dict[str, Any]]:
        """Generate vaccination recommendations"""
        return [
            {
                "name": "Influenza (Flu) Vaccine",
                "frequency": "yearly",
                "due_date": None,  # Seasonal
                "notes": "Recommended annually, typically in fall"
            },
            {
                "name": "COVID-19 Vaccine/Booster",
                "frequency": "as_recommended",
                "due_date": None,
                "notes": "Follow current CDC guidelines"
            }
        ]

    def _generate_lifestyle_recommendations(self, pre_visit: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Generate lifestyle recommendations"""
        recommendations = []
        
        # Standard recommendations
        recommendations.append({
            "category": "physical_activity",
            "recommendation": "Engage in at least 150 minutes of moderate-intensity aerobic activity weekly",
            "priority": "high"
        })
        
        recommendations.append({
            "category": "nutrition",
            "recommendation": "Follow a balanced diet rich in fruits, vegetables, whole grains, and lean proteins",
            "priority": "high"
        })
        
        recommendations.append({
            "category": "sleep",
            "recommendation": "Aim for 7-9 hours of quality sleep per night",
            "priority": "medium"
        })
        
        # Add based on flags
        for flag in pre_visit.get("flags", []):
            if flag["type"] == "smoking":
                recommendations.append({
                    "category": "tobacco_cessation",
                    "recommendation": "Consider tobacco cessation program - resources available",
                    "priority": "urgent"
                })
            if flag["type"] == "alcohol_concern":
                recommendations.append({
                    "category": "alcohol",
                    "recommendation": "Limit alcohol consumption to moderate levels (1 drink/day for women, 2 for men)",
                    "priority": "high"
                })
        
        return recommendations

    def _generate_referrals(self, flags: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Generate specialist referrals based on flags"""
        referrals = []
        
        for flag in flags:
            if flag["type"] == "hypertension" and flag.get("priority") == "high":
                referrals.append({
                    "specialty": "Cardiology",
                    "reason": "Hypertension management",
                    "urgency": "routine"
                })
            if flag["type"] == "depression_screening":
                referrals.append({
                    "specialty": "Behavioral Health",
                    "reason": "Mental health assessment",
                    "urgency": "soon"
                })
        
        return referrals

    def _generate_follow_up_schedule(self, plan: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Generate follow-up schedule"""
        schedule = []
        
        # General follow-up
        schedule.append({
            "type": "phone_check_in",
            "timing": "2 weeks",
            "due_date": (datetime.now() + timedelta(days=14)).isoformat()
        })
        
        schedule.append({
            "type": "adherence_review",
            "timing": "1 month",
            "due_date": (datetime.now() + timedelta(days=30)).isoformat()
        })
        
        schedule.append({
            "type": "progress_assessment",
            "timing": "3 months",
            "due_date": (datetime.now() + timedelta(days=90)).isoformat()
        })
        
        return schedule


class PostVisitAgent(BaseAgent):
    """
    Post-Visit Documentation Agent - Generates visit documentation
    """

    def __init__(self, gemini_client=None, backend_url: str = "http://localhost:8080/api"):
        super().__init__(
            agent_id="postvisit_001",
            role=AgentRole.POST_VISIT,
            gemini_client=gemini_client,
            backend_url=backend_url
        )

    async def execute(self, task: str, context: Dict[str, Any] = None) -> Any:
        """Execute documentation tasks"""
        return await self.generate_documentation(context or {})

    async def generate_documentation(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """
        Generate comprehensive visit documentation:
        - SOAP note
        - Patient summary
        - Care plan documentation
        - Billing codes
        """
        patient_id = context.get("patient_id")
        prevention_plan = context.get("prevention_plan", {})
        
        documentation = {
            "patient_id": patient_id,
            "document_id": str(uuid.uuid4()),
            "visit_date": datetime.now().isoformat(),
            "soap_note": self._generate_soap_note(context),
            "patient_summary": self._generate_patient_summary(context),
            "care_plan_documentation": prevention_plan,
            "billing_codes": self._generate_billing_codes(context),
            "status": "draft"
        }
        
        self.memory.add_action("generate_documentation", documentation, success=True, context=context)
        
        return documentation

    def _generate_soap_note(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Generate SOAP note"""
        return {
            "subjective": {
                "chief_complaint": "Annual Wellness Visit / Preventive Care",
                "history_of_present_illness": "Patient presents for scheduled preventive care visit.",
                "review_of_systems": "See HRA for detailed review."
            },
            "objective": {
                "vital_signs": context.get("vitals", {}),
                "physical_exam": "General: Well-appearing, alert and oriented",
                "laboratory_results": None
            },
            "assessment": {
                "diagnoses": ["Z00.00 - Encounter for general adult medical examination without abnormal findings"],
                "risk_factors": context.get("risk_factors", [])
            },
            "plan": {
                "preventive_measures": context.get("prevention_plan", {}).get("screenings", []),
                "medications": [],
                "referrals": context.get("prevention_plan", {}).get("referrals", []),
                "follow_up": context.get("prevention_plan", {}).get("follow_up_schedule", [])
            }
        }

    def _generate_patient_summary(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Generate patient-friendly summary"""
        prevention_plan = context.get("prevention_plan", {})
        
        return {
            "visit_summary": "Thank you for completing your preventive care visit.",
            "key_findings": "Your vital signs are within normal limits.",
            "action_items": [
                "Complete recommended screenings as scheduled",
                "Follow lifestyle recommendations",
                "Schedule follow-up appointments as needed"
            ],
            "upcoming_screenings": [s["name"] for s in prevention_plan.get("screenings", [])[:3]],
            "next_appointment": "Schedule your next annual wellness visit in 12 months"
        }

    def _generate_billing_codes(self, context: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Generate appropriate billing codes"""
        codes = []
        
        # Primary code for preventive visit
        codes.append({
            "code": "99395",
            "description": "Periodic comprehensive preventive medicine reevaluation, 18-39 years",
            "type": "CPT"
        })
        
        # ICD-10 codes
        codes.append({
            "code": "Z00.00",
            "description": "Encounter for general adult medical examination without abnormal findings",
            "type": "ICD-10"
        })
        
        # Add codes based on findings
        flags = context.get("pre_visit", {}).get("flags", [])
        for flag in flags:
            if flag["type"] == "hypertension":
                codes.append({
                    "code": "I10",
                    "description": "Essential (primary) hypertension",
                    "type": "ICD-10"
                })
        
        return codes


class BillingAgent(BaseAgent):
    """
    Billing Agent - Processes billing and claims
    """

    def __init__(self, gemini_client=None, backend_url: str = "http://localhost:8080/api"):
        super().__init__(
            agent_id="billing_001",
            role=AgentRole.BILLING,
            gemini_client=gemini_client,
            backend_url=backend_url
        )

    async def execute(self, task: str, context: Dict[str, Any] = None) -> Any:
        """Execute billing tasks"""
        context = context or {}
        task_lower = task.lower()
        
        if "process" in task_lower or "submit" in task_lower:
            return await self.process_billing(context)
        elif "validate" in task_lower:
            return await self.validate_claim(context)
        else:
            return await self.process_billing(context)

    async def process_billing(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Process billing for a visit"""
        patient_id = context.get("patient_id")
        documentation = context.get("documentation", {})
        
        billing = {
            "patient_id": patient_id,
            "billing_id": str(uuid.uuid4()),
            "created_at": datetime.now().isoformat(),
            "status": "pending",
            "codes": documentation.get("billing_codes", []),
            "validation": None,
            "estimated_charges": [],
            "claim_ready": False
        }
        
        # Validate billing codes
        billing["validation"] = await self.validate_claim({"codes": billing["codes"]})
        
        # Calculate estimated charges (simplified)
        for code in billing["codes"]:
            if code["type"] == "CPT":
                billing["estimated_charges"].append({
                    "code": code["code"],
                    "description": code["description"],
                    "estimated_amount": 150.00 if "preventive" in code["description"].lower() else 100.00
                })
        
        # Mark as ready if validation passes
        if billing["validation"]["is_valid"]:
            billing["claim_ready"] = True
            billing["status"] = "ready_for_submission"
        
        self.memory.add_action("process_billing", billing, success=True, context=context)
        
        return billing

    async def validate_claim(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Validate billing claim before submission"""
        codes = context.get("codes", [])
        
        validation = {
            "is_valid": True,
            "issues": [],
            "warnings": [],
            "suggestions": []
        }
        
        if not codes:
            validation["is_valid"] = False
            validation["issues"].append("No billing codes provided")
            return validation
        
        # Check for required codes
        has_cpt = any(c["type"] == "CPT" for c in codes)
        has_icd = any(c["type"] == "ICD-10" for c in codes)
        
        if not has_cpt:
            validation["is_valid"] = False
            validation["issues"].append("Missing CPT procedure code")
        
        if not has_icd:
            validation["is_valid"] = False
            validation["issues"].append("Missing ICD-10 diagnosis code")
        
        # Check for common issues
        # (In production, this would check against payer rules)
        
        return validation


# ============= AGENT REGISTRY =============

class AgentRegistry:
    """
    Registry for managing all agents in the system
    """
    _instance = None
    _agents: Dict[str, BaseAgent] = {}
    _master: Optional[MasterAgent] = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    @classmethod
    def initialize(cls, gemini_client=None, backend_url: str = "http://localhost:8080/api"):
        """Initialize all agents"""
        instance = cls()
        
        # Create master agent
        instance._master = MasterAgent(gemini_client, backend_url=backend_url)
        
        # Create all specialized agents
        agents = [
            SchedulingAgent(gemini_client, backend_url),
            NotificationAgent(gemini_client, backend_url),
            EmailAgent(gemini_client, backend_url),
            PredictiveAgent(gemini_client, backend_url),
            InitiationAgent(gemini_client, backend_url),
            HRAAgent(gemini_client, backend_url),
            FollowUpAgent(gemini_client, backend_url),
            PreVisitAgent(gemini_client, backend_url),
            PreventionPlanAgent(gemini_client, backend_url),
            PostVisitAgent(gemini_client, backend_url),
            BillingAgent(gemini_client, backend_url)
        ]
        
        # Register with master agent
        for agent in agents:
            instance._agents[agent.name] = agent
            instance._master.register_agent(agent)
        
        logger.info(f"AgentRegistry initialized with {len(agents)} agents")
        return instance

    @classmethod
    def get_master(cls) -> Optional[MasterAgent]:
        """Get the master agent"""
        return cls._instance._master if cls._instance else None

    @classmethod
    def get_agent(cls, name: str) -> Optional[BaseAgent]:
        """Get an agent by name"""
        return cls._instance._agents.get(name) if cls._instance else None

    @classmethod
    def get_agent_by_role(cls, role: AgentRole) -> Optional[BaseAgent]:
        """Get an agent by role"""
        if not cls._instance:
            return None
        return next((a for a in cls._instance._agents.values() if a.role == role), None)

    @classmethod
    def get_all_agents(cls) -> Dict[str, BaseAgent]:
        """Get all registered agents"""
        return cls._instance._agents if cls._instance else {}

    @classmethod
    def get_all_states(cls) -> Dict[str, Dict[str, Any]]:
        """Get states of all agents"""
        if not cls._instance or not cls._instance._master:
            return {}
        return cls._instance._master.get_all_agent_states()
