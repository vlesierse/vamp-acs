#!/bin/bash -e
while getopts "o:u" opt; do
    case $opt in
        o)
            orchestrator=$OPTARG
        ;;
    esac
done

if [[ -z $orchestrator ]]
then
    echo "Usage: $0 <-o orchestrator>"; exit 1;
fi

function orchestrator_dcos {
    elasticsearch='{"id":"elasticsearch","instances":1,"cpus":0.2,"mem":1024,"container":{"docker":{"image":"magneticio/elastic:2.2","network":"HOST","forcePullImage":true}},"healthChecks":[{"protocol":"TCP","gracePeriodSeconds":30,"intervalSeconds":10,"timeoutSeconds":5,"port":9200,"maxConsecutiveFailures":0}]}'
    vamp='{"id":"vamp/vamp","instances":1,"cpus":0.5,"mem":1024,"container":{"type":"DOCKER","docker":{"image":"magneticio/vamp:0.9.1-dcos","network":"BRIDGE","portMappings":[{"containerPort":8080,"hostPort":0,"name":"vip0","labels":{"VIP_0":"10.20.0.100:8080"}}],"forcePullImage":true}},"labels":{"DCOS_SERVICE_NAME":"vamp","DCOS_SERVICE_SCHEME":"http","DCOS_SERVICE_PORT_INDEX":"0"},"env":{"VAMP_WAIT_FOR":"http://elasticsearch.marathon.mesos:9200/.kibana","VAMP_PERSISTENCE_DATABASE_ELASTICSEARCH_URL":"http://elasticsearch.marathon.mesos:9200","VAMP_GATEWAY_DRIVER_LOGSTASH_HOST":"elasticsearch.marathon.mesos","VAMP_WORKFLOW_DRIVER_VAMP_URL":"http://10.20.0.100:8080","VAMP_PULSE_ELASTICSEARCH_URL":"http://elasticsearch.marathon.mesos:9200"},"healthChecks":[{"protocol":"TCP","gracePeriodSeconds":30,"intervalSeconds":10,"timeoutSeconds":5,"portIndex":0,"maxConsecutiveFailures":0}]}'
    curl -X POST http://marathon.mesos:8080/v2/apps -H 'Content-Type: application/json' -d $elasticsearch
    sleep 1m
    curl -X POST http://marathon.mesos:8080/v2/apps -H 'Content-Type: application/json' -d $vamp
}

case $orchestrator in
    dcos)
        orchestrator_dcos
    ;;
    *)
        echo "Invalid orchestrator: $orchestrator <dcos|kubernetes>"; exit 1;
    ;;
esac
