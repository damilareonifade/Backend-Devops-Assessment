<?php

namespace App\Activities;

class DataProcessingActivities
{
    public function fetchData(string $apiUrl)
    {
        static $attempt = 0;
        $attempt++;

        if ($attempt === 1) {
            throw new \Exception("Simulated API failure");
        }

        return ["data" => "Sample data from API"];
    }

    public function transformData(array $data)
    {
        return ["transformedData" => strtoupper($data['data'])];
    }

    public function saveData(array $data)
    {
        // Simulate saving data in memory
        return true;
    }
}
