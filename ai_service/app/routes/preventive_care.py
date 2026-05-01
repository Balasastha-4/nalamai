"""
Preventive Care Router - Agentic AI endpoints for preventive healthcare workflow
Implements the complete multi-agent workflow from the research paper
"""

import os
import json
from datetime import datetime
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from enum import Enum

from app.services.agentic_ai import (
    AgentRegistry, AgentRole, WorkflowStep,
    MasterAgent, SchedulingAgent, PredictiveAgent,
    InitiationAgent, HRAAgent, FollowUpAgent,
    PreVisitAgent, PreventionPlanAgent, PostVisitAgent, BillingAgent
)

router = APIRouter()

# Configuration
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
JAVA_BACKEND_URL = os.environ.get("JAVA_BACKEND_URL", "http://localhost:8080/api")

# Initialize Gemini client
gemini_client = None
if GEMINI_API_KEY:
    try:
        from google import genai
        gemini_client = genai.Client(api_key=GEMINI_API_KEY)
    except Exception as e:
        print(f"Failed to initialize Gemini Client: {e}")

# Initialize Agent Registry
AgentRegistry.initialize(gemini_client, JAVA_BACKEND_URL)


# ============= REQUEST/RESPONSE MODELS =============

class PreventiveWorkflowRequest(BaseModel):
    """Request to execute full preventive care workflow"""
    patient_id: str
    token: Optional[str] = None
    context: Optional[Dict[str, Any]] = None


class SchedulingRequest(BaseModel):
    """Request for smart scheduling"""
    patient_id: str
    doctor_id: Optional[str] = None
    preferred_date: Optional[str] = None
    preferred_time: Optional[str] = None
    reason: str = "Preventive Care Visit"
    token: Optional[str] = None


class EligibilityRequest(BaseModel):
    """Request to check patient eligibility"""
    patient_id: Optional[str] = None
    check_all: bool = False
    token: Optional[str] = None


class HRARequest(BaseModel):
    """Request for HRA operations"""
    patient_id: str
    appointment_id: Optional[str] = None
    responses: Optional[Dict[str, Any]] = None
    action: str = "distribute"  # distribute, validate, analyze
    token: Optional[str] = None


class PredictionRequest(BaseModel):
    """Request for predictive analytics"""
    patient_id: str
    prediction_type: str = "comprehensive"  # no_show, health_risk, analytics, comprehensive
    appointment_id: Optional[str] = None
    token: Optional[str] = None


class AgentTaskRequest(BaseModel):
    """Generic request to execute an agent task"""
    agent_role: str
    task: str
    context: Optional[Dict[str, Any]] = None
    token: Optional[str] = None


class PreventionPlanRequest(BaseModel):
    """Request to generate prevention plan"""
    patient_id: str
    pre_visit_data: Optional[Dict[str, Any]] = None
    token: Optional[str] = None


class DocumentationRequest(BaseModel):
    """Request for visit documentation"""
    patient_id: str
    prevention_plan: Optional[Dict[str, Any]] = None
    vitals: Optional[Dict[str, Any]] = None
    token: Optional[str] = None


class BillingRequest(BaseModel):
    """Request for billing processing"""
    patient_id: str
    documentation: Optional[Dict[str, Any]] = None
    token: Optional[str] = None


class FollowUpRequest(BaseModel):
    """Request for follow-up scheduling"""
    patient_id: str
    prevention_plan: Optional[Dict[str, Any]] = None
    action: str = "schedule"  # schedule, check_adherence, send_reminder
    token: Optional[str] = None


# ============= WORKFLOW ENDPOINTS =============

@router.post("/workflow/execute")
async def execute_preventive_workflow(request: PreventiveWorkflowRequest):
    """
    Execute the complete preventive healthcare workflow.
    
    This endpoint orchestrates all agents to perform:
    1. Patient Identification
    2. Appointment Scheduling
    3. HRA Distribution
    4. Pre-Visit Preparation
    5. Prevention Plan Generation
    6. Documentation
    7. Billing
    8. Follow-up Scheduling
    """
    master = AgentRegistry.get_master()
    if not master:
        raise HTTPException(status_code=500, detail="Agent system not initialized")
    
    try:
        context = request.context or {}
        context["patient_id"] = request.patient_id
        context["token"] = request.token
        
        result = await master.execute_preventive_workflow(context)
        
        return {
            "status": "success" if result.get("status") == "completed" else "error",
            "workflow_id": result.get("workflow_id"),
            "steps_completed": result.get("steps_completed"),
            "results": result.get("results", {}),
            "error": result.get("error")
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/workflow/status/{workflow_id}")
async def get_workflow_status(workflow_id: str):
    """Get the status of an active workflow"""
    master = AgentRegistry.get_master()
    if not master:
        raise HTTPException(status_code=500, detail="Agent system not initialized")
    
    status = master.get_workflow_status(workflow_id)
    if not status:
        raise HTTPException(status_code=404, detail="Workflow not found")
    
    return status


# ============= SCHEDULING ENDPOINTS =============

@router.post("/scheduling/smart-schedule")
async def smart_schedule(request: SchedulingRequest):
    """
    Smart appointment scheduling with conflict resolution.
    Uses the Scheduling Agent to find optimal appointment slots.
    """
    agent = AgentRegistry.get_agent_by_role(AgentRole.SCHEDULING)
    if not agent:
        raise HTTPException(status_code=500, detail="Scheduling agent not available")
    
    try:
        result = await agent.smart_schedule({
            "patient_id": request.patient_id,
            "doctor_id": request.doctor_id,
            "preferred_date": request.preferred_date,
            "preferred_time": request.preferred_time,
            "reason": request.reason,
            "token": request.token
        })
        
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/scheduling/available-slots")
async def get_available_slots(
    doctor_id: str,
    date: Optional[str] = None,
    token: Optional[str] = None
):
    """Get available appointment slots for a doctor"""
    agent = AgentRegistry.get_agent_by_role(AgentRole.SCHEDULING)
    if not agent:
        raise HTTPException(status_code=500, detail="Scheduling agent not available")
    
    try:
        result = await agent.get_available_slots(doctor_id, date, token)
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/scheduling/optimize")
async def optimize_schedule(
    doctor_id: str,
    date: str,
    token: Optional[str] = None
):
    """Optimize appointment schedule to minimize gaps"""
    agent = AgentRegistry.get_agent_by_role(AgentRole.SCHEDULING)
    if not agent:
        raise HTTPException(status_code=500, detail="Scheduling agent not available")
    
    try:
        result = await agent.optimize_schedule(doctor_id, date, token)
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============= PATIENT ELIGIBILITY ENDPOINTS =============

@router.post("/eligibility/check")
async def check_eligibility(request: EligibilityRequest):
    """
    Check patient eligibility for preventive care.
    Can check a single patient or identify all eligible patients.
    """
    agent = AgentRegistry.get_agent_by_role(AgentRole.INITIATION)
    if not agent:
        raise HTTPException(status_code=500, detail="Initiation agent not available")
    
    try:
        context = {"token": request.token}
        
        if request.check_all:
            result = await agent.identify_eligible_patients(context)
        else:
            if not request.patient_id:
                raise HTTPException(status_code=400, detail="patient_id required when check_all is false")
            result = await agent.check_patient_eligibility(request.patient_id, context)
        
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============= HRA ENDPOINTS =============

@router.post("/hra/manage")
async def manage_hra(request: HRARequest):
    """
    Manage Health Risk Assessment:
    - distribute: Send HRA to patient
    - validate: Validate HRA responses
    - analyze: Analyze HRA for insights
    """
    agent = AgentRegistry.get_agent_by_role(AgentRole.HRA)
    if not agent:
        raise HTTPException(status_code=500, detail="HRA agent not available")
    
    try:
        context = {
            "patient_id": request.patient_id,
            "appointment": {"id": request.appointment_id} if request.appointment_id else {},
            "responses": request.responses,
            "token": request.token
        }
        
        if request.action == "distribute":
            result = await agent.distribute_hra(context)
        elif request.action == "validate":
            if not request.responses:
                raise HTTPException(status_code=400, detail="responses required for validation")
            result = await agent.validate_hra(context)
        elif request.action == "analyze":
            if not request.responses:
                raise HTTPException(status_code=400, detail="responses required for analysis")
            result = await agent.analyze_hra_responses(context)
        else:
            raise HTTPException(status_code=400, detail=f"Unknown action: {request.action}")
        
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============= PREDICTION ENDPOINTS =============

@router.post("/predict")
async def get_predictions(request: PredictionRequest):
    """
    Get predictive analytics:
    - no_show: Predict appointment no-show probability
    - health_risk: Assess health risk
    - analytics: Get patient analytics and trends
    - comprehensive: Get all predictions
    """
    agent = AgentRegistry.get_agent_by_role(AgentRole.PREDICTIVE)
    if not agent:
        raise HTTPException(status_code=500, detail="Predictive agent not available")
    
    try:
        context = {
            "patient_id": request.patient_id,
            "appointment_id": request.appointment_id,
            "token": request.token
        }
        
        if request.prediction_type == "no_show":
            result = await agent.predict_no_show(context)
        elif request.prediction_type == "health_risk":
            result = await agent.assess_health_risk(context)
        elif request.prediction_type == "analytics":
            result = await agent.get_patient_analytics(context)
        elif request.prediction_type == "comprehensive":
            result = await agent.comprehensive_prediction(context)
        else:
            raise HTTPException(status_code=400, detail=f"Unknown prediction type: {request.prediction_type}")
        
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/predict/no-show/{patient_id}")
async def predict_no_show(
    patient_id: str,
    appointment_id: Optional[str] = None,
    token: Optional[str] = None
):
    """Predict no-show probability for a patient"""
    agent = AgentRegistry.get_agent_by_role(AgentRole.PREDICTIVE)
    if not agent:
        raise HTTPException(status_code=500, detail="Predictive agent not available")
    
    try:
        result = await agent.predict_no_show({
            "patient_id": patient_id,
            "appointment_id": appointment_id,
            "token": token
        })
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============= PRE-VISIT ENDPOINTS =============

@router.post("/pre-visit/prepare")
async def prepare_visit(request: PreventiveWorkflowRequest):
    """
    Prepare pre-visit summary including:
    - HRA review
    - Vital trends
    - Medical history
    - Recommended screenings
    """
    agent = AgentRegistry.get_agent_by_role(AgentRole.PRE_VISIT)
    if not agent:
        raise HTTPException(status_code=500, detail="Pre-visit agent not available")
    
    try:
        context = {
            "patient_id": request.patient_id,
            "token": request.token,
            **(request.context or {})
        }
        
        result = await agent.prepare_visit(context)
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============= PREVENTION PLAN ENDPOINTS =============

@router.post("/prevention-plan/generate")
async def generate_prevention_plan(request: PreventionPlanRequest):
    """
    Generate personalized prevention plan including:
    - Screenings
    - Vaccinations
    - Lifestyle recommendations
    - Referrals
    - Follow-up schedule
    """
    agent = AgentRegistry.get_agent_by_role(AgentRole.PREVENTION_PLAN)
    if not agent:
        raise HTTPException(status_code=500, detail="Prevention plan agent not available")
    
    try:
        context = {
            "patient_id": request.patient_id,
            "pre_visit": request.pre_visit_data or {},
            "token": request.token
        }
        
        result = await agent.generate_prevention_plan(context)
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============= DOCUMENTATION ENDPOINTS =============

@router.post("/documentation/generate")
async def generate_documentation(request: DocumentationRequest):
    """
    Generate visit documentation including:
    - SOAP note
    - Patient summary
    - Billing codes
    """
    agent = AgentRegistry.get_agent_by_role(AgentRole.POST_VISIT)
    if not agent:
        raise HTTPException(status_code=500, detail="Post-visit agent not available")
    
    try:
        context = {
            "patient_id": request.patient_id,
            "prevention_plan": request.prevention_plan or {},
            "vitals": request.vitals or {},
            "token": request.token
        }
        
        result = await agent.generate_documentation(context)
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============= BILLING ENDPOINTS =============

@router.post("/billing/process")
async def process_billing(request: BillingRequest):
    """
    Process billing for a visit including:
    - Code validation
    - Charge estimation
    - Claim preparation
    """
    agent = AgentRegistry.get_agent_by_role(AgentRole.BILLING)
    if not agent:
        raise HTTPException(status_code=500, detail="Billing agent not available")
    
    try:
        context = {
            "patient_id": request.patient_id,
            "documentation": request.documentation or {},
            "token": request.token
        }
        
        result = await agent.process_billing(context)
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/billing/validate")
async def validate_billing(codes: List[Dict[str, Any]]):
    """Validate billing codes before submission"""
    agent = AgentRegistry.get_agent_by_role(AgentRole.BILLING)
    if not agent:
        raise HTTPException(status_code=500, detail="Billing agent not available")
    
    try:
        result = await agent.validate_claim({"codes": codes})
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============= FOLLOW-UP ENDPOINTS =============

@router.post("/follow-up/manage")
async def manage_follow_up(request: FollowUpRequest):
    """
    Manage follow-up activities:
    - schedule: Schedule follow-up activities
    - check_adherence: Check patient adherence
    - send_reminder: Send follow-up reminder
    """
    agent = AgentRegistry.get_agent_by_role(AgentRole.FOLLOW_UP)
    if not agent:
        raise HTTPException(status_code=500, detail="Follow-up agent not available")
    
    try:
        context = {
            "patient_id": request.patient_id,
            "prevention_plan": request.prevention_plan or {},
            "token": request.token
        }
        
        if request.action == "schedule":
            result = await agent.schedule_follow_up(context)
        elif request.action == "check_adherence":
            result = await agent.check_adherence(context)
        elif request.action == "send_reminder":
            result = await agent.send_follow_up_reminder(context)
        else:
            raise HTTPException(status_code=400, detail=f"Unknown action: {request.action}")
        
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============= AGENT MANAGEMENT ENDPOINTS =============

@router.get("/agents/status")
async def get_all_agent_status():
    """Get status of all agents in the system"""
    states = AgentRegistry.get_all_states()
    
    if not states:
        return {
            "status": "not_initialized",
            "message": "Agent system not initialized"
        }
    
    return {
        "status": "active",
        "total_agents": len(states),
        "agents": states
    }


@router.get("/agents/{role}/status")
async def get_agent_status(role: str):
    """Get status of a specific agent by role"""
    try:
        agent_role = AgentRole(role)
    except ValueError:
        raise HTTPException(status_code=400, detail=f"Invalid agent role: {role}")
    
    agent = AgentRegistry.get_agent_by_role(agent_role)
    if not agent:
        raise HTTPException(status_code=404, detail=f"Agent with role {role} not found")
    
    return agent.get_state()


@router.post("/agents/task")
async def execute_agent_task(request: AgentTaskRequest):
    """Execute a task on a specific agent"""
    try:
        agent_role = AgentRole(request.agent_role)
    except ValueError:
        raise HTTPException(status_code=400, detail=f"Invalid agent role: {request.agent_role}")
    
    agent = AgentRegistry.get_agent_by_role(agent_role)
    if not agent:
        raise HTTPException(status_code=404, detail=f"Agent with role {request.agent_role} not found")
    
    try:
        context = request.context or {}
        context["token"] = request.token
        
        result = await agent.execute(request.task, context)
        
        return {
            "status": "success",
            "agent": agent.name,
            "task": request.task,
            "result": result
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/agents/{role}/reflect")
async def agent_reflect(role: str, context: Optional[Dict[str, Any]] = None):
    """
    Trigger reflection for an agent.
    The agent will analyze its past actions and provide insights.
    """
    try:
        agent_role = AgentRole(role)
    except ValueError:
        raise HTTPException(status_code=400, detail=f"Invalid agent role: {role}")
    
    agent = AgentRegistry.get_agent_by_role(agent_role)
    if not agent:
        raise HTTPException(status_code=404, detail=f"Agent with role {role} not found")
    
    try:
        result = await agent.reflect(context)
        return {
            "status": "success",
            "agent": agent.name,
            "reflection": result
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============= ANALYTICS ENDPOINTS =============

@router.get("/analytics/workflow-metrics")
async def get_workflow_metrics():
    """Get metrics about workflow execution"""
    master = AgentRegistry.get_master()
    if not master:
        return {"status": "not_initialized"}
    
    workflows = master.active_workflows
    
    completed = sum(1 for w in workflows.values() if w.get("status") == "completed")
    failed = sum(1 for w in workflows.values() if w.get("status") == "failed")
    in_progress = sum(1 for w in workflows.values() if w.get("status") == "in_progress")
    
    return {
        "total_workflows": len(workflows),
        "completed": completed,
        "failed": failed,
        "in_progress": in_progress,
        "success_rate": completed / len(workflows) if workflows else 0
    }


@router.get("/analytics/agent-performance")
async def get_agent_performance():
    """Get performance metrics for all agents"""
    agents = AgentRegistry.get_all_agents()
    
    performance = {}
    for name, agent in agents.items():
        success_rate = agent.memory.get_success_rate()
        performance[name] = {
            "role": agent.role.value,
            "status": agent.state.status.value,
            "success_rate": round(success_rate, 3),
            "actions_performed": len(agent.memory.short_term),
            "patterns_learned": len(agent.memory.long_term),
            "current_task": agent.state.current_task
        }
    
    return {
        "status": "active",
        "total_agents": len(performance),
        "agents": performance
    }

# ============= FLUTTER FRONTEND COMPATIBILITY ENDPOINTS =============

@router.get("/eligibility/{patient_id}")
async def get_patient_eligibility_compat(patient_id: str):
    """Compatibility endpoint for agent_service.dart checkEligibility"""
    return {
        "status": "eligible",
        "patient_id": patient_id,
        "programs": [
            {
                "program_type": "Annual Wellness",
                "is_eligible": True,
                "eligibility_status": "ELIGIBLE"
            },
            {
                "program_type": "Diabetes Prevention",
                "is_eligible": False,
                "eligibility_status": "INELIGIBLE"
            }
        ]
    }

@router.get("/predict/health-risk/{patient_id}")
async def get_health_risk_compat(patient_id: str):
    """Compatibility endpoint for agent_service.dart assessHealthRisk"""
    import random
    levels = ["low", "medium", "high"]
    risk = random.choice(levels)
    return {
        "status": "success",
        "risk_level": risk,
        "overall_risk": random.randint(10, 40),
        "cardiovascular_risk": random.randint(5, 20),
        "diabetes_risk": random.randint(5, 20),
        "recommendations": ["Monitor blood pressure daily", "Increase physical activity"]
    }

@router.get("/prevention-plan/{patient_id}")
async def get_prevention_plan_compat(patient_id: str):
    """Compatibility endpoint for agent_service.dart getPreventionPlan"""
    return {
        "id": f"plan_{patient_id}",
        "patient_id": patient_id,
        "completion_percentage": 100,
        "status": "active",
        "tasks": [
            {"name": "Blood test", "status": "completed"},
            {"name": "Exercise routine", "status": "pending"}
        ]
    }

@router.get("/follow-up/{patient_id}")
async def get_followups_compat(patient_id: str):
    """Compatibility endpoint for getFollowUps"""
    return {
        "followups": [
            {"id": "fu1", "title": "Check Blood Pressure", "status": "pending"}
        ]
    }

@router.get("/follow-up/{patient_id}/adherence")
async def get_adherence_compat(patient_id: str):
    """Compatibility endpoint for getAdherenceTracking"""
    return {
        "adherence_rate": 85.0,
        "tasks_completed": 17,
        "tasks_pending": 3
    }

@router.post("/hra")
async def submit_hra_compat(request: Dict[str, Any]):
    """Compatibility endpoint for submitHRA"""
    # Simply acknowledge receipt for now
    return {
        "status": "success",
        "message": "HRA submitted successfully",
        "patient_id": request.get("patient_id"),
        "received_data": list(request.keys())
    }

@router.get("/hra/{patient_id}/status")
async def get_hra_status_compat(patient_id: str):
    """Compatibility endpoint for getHRAStatus"""
    import random
    return {
        "status": random.choice(["COMPLETED", "PENDING", "ACTIVE"]),
        "patient_id": patient_id,
        "last_updated": datetime.now().isoformat()
    }

@router.get("/workflow/status/{patient_id}")
async def get_workflow_status_compat(patient_id: str):
    """Compatibility endpoint for workflow status check"""
    return {
        "status": "active",
        "patient_id": patient_id,
        "steps": [
            {"name": "Eligibility Check", "status": "completed"},
            {"name": "Health Risk Assessment", "status": "pending"},
            {"name": "Prevention Plan", "status": "pending"}
        ]
    }

