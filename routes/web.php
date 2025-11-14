<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\TemporalWorkflowController;

Route::get('/', function () {
    return view('welcome');
});

Route::post('/start-workflow', [TemporalWorkflowController::class, 'startWorkflow']);
