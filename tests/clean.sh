#!/bin/bash

echo "Start cleaning up potentially leaking resources from previous test executions. Warnings about missing resources should be ignored"

CF_ORG=${TEST_ORG_NAME:-pcfdev-org}
CF_SPACE=${TEST_SPACE_NAME:-pcfdev-space}

if [ -z "$CF_API_URL" ] || [ -z "$CF_USER" ] || [ -z "$CF_PASSWORD" ]; then
   echo "ERROR: the script runs probably on a PR from a fork - terminating";
   exit 1;
fi

# we have no more shared platform :(
#exit 0

#set -e # Exit if the login fails (not set or wrongly set!)
cf api $CF_API_URL --skip-ssl-validation
cf login -u $CF_USER -p $CF_PASSWORD -o $CF_ORG -s $CF_SPACE
#set +e

# Please add any further resources do not get destroyed

# Delete apps
cf delete -f php-app &> /dev/null
cf delete -f basic-auth-router &> /dev/null
cf delete -f basic-auth-broker &> /dev/null
cf delete -f fake-service-broker &> /dev/null
cf delete -f test-app &> /dev/null
cf delete -f dummy-app &> /dev/null
cf delete -f test-docker-app &> /dev/null
cf delete -f spring-music &> /dev/null
cf delete -f java-spring &> /dev/null
cf delete -f net-policy-res-back &> /dev/null
cf delete -f net-policy-res-front &> /dev/null

# Delete org and security gorups

cf delete-org -f myorg &> /dev/null
cf delete-org -f myorg-ds-space &> /dev/null
cf delete-org -f myorg-ds-org &> /dev/null
cf delete-org -f myorg-ds-domain &> /dev/null
cf delete-org -f org1 &> /dev/null
cf delete-org -f org2 &> /dev/null
cf delete-org -f org3 &> /dev/null
cf delete-org -f organization-one &> /dev/null
cf delete-org -f organization-ds-space &> /dev/null
cf delete-org -f organization-one-updated &> /dev/null
cf delete-org -f quota-org &> /dev/null
cf delete-security-group -f app-services1 &> /dev/null
cf delete-security-group -f app-services2 &> /dev/null
cf delete-security-group -f app-services3 &> /dev/null
cf delete-security-group -f app-services &> /dev/null

# Delete quotas
cf delete-space-quota -f 10g-space &> /dev/null
cf delete-space-quota -f 20g-space-ds &> /dev/null
cf delete-quota       -f 100g-org &> /dev/null
cf delete-quota       -f 100g-org-ds &> /dev/null
cf delete-quota       -f 50g-org &> /dev/null

# Delete services and service instances
cf delete-service -f basic-auth &> /dev/null
cf delete-service -f rabbitmq &> /dev/null
cf delete-service -f db &> /dev/null
cf delete-service -f fs1 &> /dev/null
cf purge-service-offering -f p-basic-auth &> /dev/null
cf delete-service-broker -f basic-auth &> /dev/null
cf delete-service-broker -f test &> /dev/null
cf delete-service-broker -f test-renamed &> /dev/null

# Delete routes
cf unbind-route-service -f $TEST_APP_DOMAIN basic-auth --hostname php-app &> /dev/null
cf delete-orphaned-routes -f &> /dev/null

# Delete domains
#
# We don't need to delete owned domains by dynamically created orgs as they are recursively deleted when associated
# org gets deleted

# Delete users

cf delete-user manager1@acme.com -f &> /dev/null
cf delete-user auditor@acme.com -f &> /dev/null
cf delete-user teamlead@acme.com -f &> /dev/null
cf delete-user developer1@acme.com -f &> /dev/null
cf delete-user developer2@acme.com -f &> /dev/null
cf delete-user developer3@acme.com -f &> /dev/null
cf delete-user cf-admin -f &> /dev/null
cf delete-user test-user1@acme.com -f &> /dev/null
cf delete-user test-user2@acme.com -f &> /dev/null
cf delete-user test-user3@acme.com -f &> /dev/null
cf delete-user test-user4@acme.com -f &> /dev/null
cf delete-user test-user5@acme.com -f &> /dev/null

 # Delete quotas

 cf delete-quota runaway_test -f &> /dev/null


# url=$(cf curl /v2/service_brokers | jq -r '.resources[] | select(.entity.name | contains("basic-auth")) | .metadata.url')
# if [ ! -z "${url}" ]; then
#     echo deleting ${url}
#     cf curl -X DELETE ${url}
# fi

# Sanity checks

CF_SPACE_GUID=`cf space --guid $CF_SPACE`
CF_ORG_GUID=`cf org --guid $CF_ORG`

if [ `cf curl "/v2/apps?q=space_guid:$CF_SPACE_GUID" | jq ".total_results"` -ne "0" ]; then
   echo "ERROR: The acceptance environment contains some residual apps, run \"cf a\" - please clean them up using a PR on clean.sh";
   cf a
   exit 1;
fi

if [ `cf curl "/v2/routes?q=organization_guid:$CF_ORG_GUID" \
   | jq '[ .resources[] | select(.entity.space_guid == "'$CF_SPACE_GUID'") ] | length'` -ne "0" ]; then

   echo "ERROR: The acceptance environment contains some residual routes, run \"cf routes\" - please clean them up using a PR on clean.sh";
   cf routes
   exit 1;
fi

if [ `cf curl "/v2/service_instances?q=organization_guid:$CF_ORG_GUID" \
   | jq '[ .resources[] | select(.entity.space_guid == "'$CF_SPACE_GUID'") ] | length'` -ne "0" ]; then

   echo "ERROR: The acceptance environment contains some residual service instances, run \"cf s\" - please clean them up using a PR on clean.sh";
   cf s
   exit 1;
fi

echo "Completed cleaning up potentially leaking resources from previous test executions."
exit 0
