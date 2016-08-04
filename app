#!/usr/bin/env php
<?php

require_once __DIR__ . '/vendor/autoload.php';


use GuzzleHttp\Client as GuzzleClient;
use Doctrine\DBAL\Configuration as DoctrineConfiguration;
use Doctrine\DBAL\DriverManager;

$config = new DoctrineConfiguration();

$connectionParams = array(
    'dbname' => 'mydb',
    'user' => 'user',
    'password' => 'secret',
    'host' => 'localhost',
    'driver' => 'pdo_mysql',
);
$connectionParams = array(
    'url' => 'pgsql://homestead:secret@localhost:54320/h64',
);
$conn = DriverManager::getConnection($connectionParams, $config);

$guzzle = new GuzzleClient([
    'base_uri' => 'http://tracker.ets2map.com/v2/',
]);

$conn->query("CREATE TABLE IF NOT EXISTS truck
(
    x TEXT,
    y TEXT,
    z TEXT,
    server INT,
    mpId INT,
    name TEXT
);");

while (true) {

    $rustart = getrusage();

    $res = $guzzle->get('0/0/0/30000000');
    $body = (string)$res->getBody();

    $json = json_decode($body, true, 512, JSON_BIGINT_AS_STRING);
    $count = 0;

    $conn->beginTransaction();
    try {
        foreach ($json['Trucks'] as $truck) {
            $count++;
            $data['x'] = $truck['x'];
            $data['y'] = $truck['y'];
            $data['z'] = $truck['h'];
            $data['server'] = $truck['server'];
            $data['name'] = $truck['name'];
            $data['mpId'] = $truck['mp_id'];

            $conn->insert('truck', $data);
        }
        $conn->commit();
    } catch(Exception $e) {
        $conn->rollBack();
        echo $e->getMessage();
    }
    $ru = getrusage();
    echo $count ." items, " . rutime($ru, $rustart, "utime") .
        " ms computations, ";
    echo rutime($ru, $rustart, "stime") . " ms syscalls\n";

    sleep(10);
}


function rutime($ru, $rus, $index) {
    return ($ru["ru_$index.tv_sec"]*1000 + intval($ru["ru_$index.tv_usec"]/1000))
    -  ($rus["ru_$index.tv_sec"]*1000 + intval($rus["ru_$index.tv_usec"]/1000));
}