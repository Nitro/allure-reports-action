#! /usr/bin/env bash

unset JAVA_HOME

REPOSITORY_OWNER_SLASH_NAME=${INPUT_GITHUB_REPO}
REPOSITORY_NAME=${REPOSITORY_OWNER_SLASH_NAME##*/}
S3_WEBSITE_URL="https://${INPUT_S3_BUCKET_DNS}/${REPOSITORY_NAME}"

mkdir -p ./${INPUT_S3_BUCKET}

if [[ $(aws s3 ls s3://${INPUT_S3_BUCKET}/${REPOSITORY_NAME} --region ${INPUT_S3_REGION} | head) ]]; then 
    echo "Pre-existing history found, fetching..."
    aws s3 sync s3://${INPUT_S3_BUCKET}/${REPOSITORY_NAME} ./${INPUT_S3_BUCKET} --region ${INPUT_S3_REGION}
else 
    echo "Couldn't locate pre-existing reports, continuing..." 
fi

mkdir -p ./${INPUT_ALLURE_HISTORY}
cp -r ./${INPUT_S3_BUCKET}/. ./${INPUT_ALLURE_HISTORY}

echo "<!DOCTYPE html><meta charset=\"utf-8\"><meta http-equiv=\"refresh\" content=\"0; URL=${S3_WEBSITE_URL}/${INPUT_GITHUB_RUN_NUM}/\">" > ./${INPUT_ALLURE_HISTORY}/index.html
echo "<meta http-equiv=\"Pragma\" content=\"no-cache\"><meta http-equiv=\"Expires\" content=\"0\">" >> ./${INPUT_ALLURE_HISTORY}/index.html

echo '{"name":"GitHub Actions","type":"github","reportName":"Allure Report with history",' > executor.json
echo "\"url\":\"${S3_WEBSITE_URL}\"," >> executor.json
echo "\"reportUrl\":\"${S3_WEBSITE_URL}/${INPUT_GITHUB_RUN_NUM}/\"," >> executor.json
echo "\"buildUrl\":\"https://github.com/${INPUT_GITHUB_REPO}/actions/runs/${INPUT_GITHUB_RUN_ID}\"," >> executor.json
echo "\"buildName\":\"GitHub Actions Run #${INPUT_GITHUB_RUN_ID}\",\"buildOrder\":\"${INPUT_GITHUB_RUN_NUM}\"}" >> executor.json
mv ./executor.json ./${INPUT_TEST_RESULTS}

echo "URL=${S3_WEBSITE_URL}" > environment.properties
mv ./environment.properties ./${INPUT_TEST_RESULTS}

echo "keep allure history from ${INPUT_ALLURE_HISTORY}/last-history to ${INPUT_TEST_RESULTS}/history"
cp -r ./${INPUT_ALLURE_HISTORY}/last-history/. ./${INPUT_TEST_RESULTS}/history

echo "generating report from ${INPUT_TEST_RESULTS} to ${INPUT_ALLURE_REPORT} ..."
allure generate --clean ${INPUT_TEST_RESULTS} -o ${INPUT_ALLURE_REPORT}

echo "copy allure-report to ${INPUT_ALLURE_HISTORY}/${INPUT_GITHUB_RUN_NUM}"
cp -r ./${INPUT_ALLURE_REPORT}/. ./${INPUT_ALLURE_HISTORY}/${INPUT_GITHUB_RUN_NUM}
echo "copy allure-report history to /${INPUT_ALLURE_HISTORY}/last-history"
cp -r ./${INPUT_ALLURE_REPORT}/history/. ./${INPUT_ALLURE_HISTORY}/last-history

aws s3 sync ${INPUT_ALLURE_HISTORY} s3://${INPUT_S3_BUCKET}/${REPOSITORY_NAME} --region ${INPUT_S3_REGION}
