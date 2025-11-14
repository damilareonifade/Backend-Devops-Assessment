<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Prometheus\CollectorRegistry;
use Prometheus\Storage\InMemory;

class PrometheusServiceProvider extends ServiceProvider
{
    public function register()
    {
        $this->app->singleton(CollectorRegistry::class, function () {
            return new CollectorRegistry(new InMemory());
        });
    }

    public function boot(CollectorRegistry $registry)
    {
        $registry->getOrRegisterCounter('workflow', 'executions_total', 'Total workflow executions');
        $registry->getOrRegisterCounter('workflow', 'failures_total', 'Total workflow failures');
        $registry->getOrRegisterCounter('workflow', 'retries_total', 'Total workflow retries');
    }
}
