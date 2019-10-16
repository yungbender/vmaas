if [[ "$VULNERABILITY_DOCS_TOKEN" == "" ]]
then 
    echo "Cannot find github token for pushing into docs repo."
    exit 1
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch of vmaas: $BRANCH"

if [[ "$BRANCH" != "master" ]] || [[ "$BRANCH" != "stable" ]]
then
    echo "Database schema is updated only on pushes into master/stable."
    exit 0
fi


echo "Creating output directory for docs:"
mkdir output

echo "Starting schemaspy container and creating docs:"
cd ..
docker-compose -f docker-compose-dbdocs.yml up --build schema_spy

echo "Stopping containers:"
docker container stop vmaas-database

echo "Moving the schema image:"
cd scripts
git clone https://github.com/RedHatInsights/vulnerability-docs.git db_docs
if [[ "$BRANCH" == "stable" ]]
then
    rm /db_docs/vmaas_database_stable/*
    mv /output/* /db_docs/vmaas_database_stable/
else
    rm /db_docs/vmaas_database_master/*
    mv /output/* /db_docs/vmaas_database_master/
fi

COMMIT_MESSAGE="$(date) Update database schema for commit $(git rev-parse --short HEAD): $(git log -1 --pretty=%B)"
GIT_LOCATION="https://vmaas-bot:${VULNERABILITY_DOCS_TOKEN}@github.com/RedHatInsights/vulnerability-docs.git"

cd db_docs
git add .
git commit -m "$COMMIT_MESSAGE"
git push "$GIT_LOCATION"

cd ..
rm -rf db_docs
rm -rf output
