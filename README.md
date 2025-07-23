# plan for system:

FastAPI + Dynamodb (local with docker for pef test first, then cloud later )
-> full docker 

added opensearch for fast query and email system


# Data Models ( API documentation for detail)
models.py -> keep simple for demo purpose
there is additional EventAttendance table for attentdance in main table (Single table mode)
Email table for tracking status

# places for improvement based on product requirement:
add history for event edit/EventUpdate 


# dev

## Run Locally
uvicorn app.main:app --reload

## reset tabl
python -m app.db.init

## run test
python -m pytest test/test_crm.py

python -m pytest test/test_crm.py -k test_duplicate_email_should_fail -s

## create large user dataset
python -m pytest stress_test/rand_users.py -s

### Test coverage

python -m pytest test/test_crm.py --cov=app --cov-report=term-missing
    
===================================================================================================== tests coverage 
Name                           Stmts   Miss  Cover   Missing
------------------------------------------------------------
app/__init__.py                    0      0   100%
app/db/init.py                    34      9    74%   74-75, 108-109, 128-132, 140
app/db/session.py                 13      4    69%   19-20, 24-25
app/main.py                       17      4    76%   12-16
app/models.py                    110     11    90%   83-85, 134-137, 142-145
app/opensearch/client.py           9      3    67%   8-13
app/query/filter_users.py         92     26    72%   29, 35-36, 43, 49, 59, 67, 74-86, 104, 122, 124, 126, 133, 141, 161-162
app/routes/attendance.py          30      7    77%   35-40, 53-59
app/routes/email.py               56     21    62%   20, 54-59, 65-81, 85-101
app/routes/events.py              58      1    98%   94
app/routes/users.py               59      4    93%   16, 77, 108-109
app/services/email_sender.py       2      0   100%
------------------------------------------------------------
TOTAL                            480     90    81%


# LOGS
day 1: full datamodel + dynamodb + simple test case
day 2: open search + test large case (~10000 user), fix minor bugs
day 3: test, add run_in_threadpool, deploy docker
day 4: connect to AWS


docker build -f docker/Dockerfile . -t emcrm-api && docker run -p 8123:8080 emcrm-api


# run test

docker compose -f docker/docker-compose.yml run --rm api python -m pytest test/test_crm.py


# run final

docker compose -f docker/docker-compose.yml up