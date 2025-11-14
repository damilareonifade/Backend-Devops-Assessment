<?php

namespace App\Http\Controllers;

use Temporal\Client\WorkflowClient;
use Temporal\Worker\WorkerFactory;
use Temporal\Worker\WorkerOptions;
use Illuminate\Http\Request;

class TemporalWorkflowController extends Controller
{
    private $workflowClient;

    public function __construct()
    {
        $this->workflowClient = WorkflowClient::create();
    }

    public function startWorkflow(Request $request)
    {
        $workflow = $this->workflowClient->newWorkflowStub(
            'App\Workflows\DataProcessingWorkflow',
            WorkflowClient::options()
        );

        try {
            $result = $workflow->run($request->all());
            return response()->json(['status' => 'success', 'result' => $result]);
        } catch (\Exception $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }
}
