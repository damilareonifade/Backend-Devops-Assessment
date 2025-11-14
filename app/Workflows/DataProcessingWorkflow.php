<?php

namespace App\Workflows;

use Temporal\Activity\ActivityOptions;
use Temporal\Workflow\Workflow;
use Temporal\Common\RetryOptions;
use Carbon\Carbon;

class DataProcessingWorkflow
{
    /** @var \App\Activities\DataProcessingActivities */
    private $activities;

    public function __construct()
    {
        $this->activities = Workflow::newActivityStub(
            \App\Activities\DataProcessingActivities::class,
            ActivityOptions::new()
                ->withStartToCloseTimeout(Carbon::now()->addSeconds(30))
                ->withRetryOptions(
                    RetryOptions::new()
                        ->withMaximumAttempts(3)
                )
        );
    }

    public function run(array $input)
    {
        $data = $this->activities->fetchData($input['apiUrl']);
        $transformedData = $this->activities->transformData($data);
        $this->activities->saveData($transformedData);

        return $transformedData;
    }
}