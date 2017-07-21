
# # Provide the parameter names in the order that they are provided. 
# # BASE_ARGS is the overarching argument list, but processing shifts
# # when NUMBER_OF_EVALUATION_ENTITIES is hit. At that point it starts
# # evaluating for EVALUATION_ENTITY_ARGS for n in $NUMBER_OF_EVALUATION_ENTITIES
# # sets of arguments. Once all of those argument sets are finished, it will
# # move on to SUMMARY_MESSAGE and so on. 
# BASE_ARGS="APP_NAME APP_ID PVN_ALERT_TIME PRIORITY SEVERITY TAG HEALTH_RULE_NAME \
#       HEALTH_RULE_ID PVN_TIME_PERIOD_IN_MINUTES AFFECTED_ENTITY_TYPE \
#       AFFECTED_ENTITY_NAME AFFECTED_ENTITY_ID NUMBER_OF_EVALUATION_ENTITIES \
#       SUMMARY_MESSAGE INCIDENT_ID DEEP_LINK_URL EVENT_TYPE ACCOUNT_NAME \
#       ACCOUNT_ID"

# # Same as BASE_ARGS, but this is the argument set for an evaluation entity.
# # Once NUMBER_OF_TRIGGERED_CONDITIONS_PER_EVALUATION_ENTITY is reached, it
# # starts evaluating for TRIGGERED_CONDITION_ARGS for n in 
# # $NUMBER_OF_TRIGGERED_CONDITIONS_PER_EVALUATION_ENTITY sets of arguments.
# # For now, unlike BASE_ARGS, we stop after evaluating the triggered conditions
# # per evaluation entity, but adding arguments to this list will continue
# # processing those as well, since it's the same mechanism over this set
# # of data instead. 
# # However, we will suffix the index of the evaluation entity to each of these
# # names. So EVALUATION_ENTITY_TYPE will actually be EVALUATION_ENTITY_TYPE_0
# # for the first element, etc.
# EVALUATION_ENTITY_ARGS="EVALUATION_ENTITY_TYPE EVALUATION_ENTITY_NAME \
#                         EVALUATION_ENTITY_ID \
#                         NUMBER_OF_TRIGGERED_CONDITIONS_PER_EVALUATION_ENTITY"

# # See above, but the argument set for a triggered condition for an evaluation
# # entity. 
# TRIGGERED_CONDITION_ARGS="SCOPE_TYPE SCOPE_NAME SCOPE_ID CONDITION_NAME \
#                           CONDITION_ID OPERATOR CONDITION_UNIT_TYPE \
#                           THRESHOLD_VALUE OBSERVED_VALUE"

# TC_BASELINE_ARGS="USE_DEFAULT_BASELINE BASELINE_NAME BASELINE_ID"

echo "=== Test with default baseline, one evaluation, one condition ==="
sh custom/actions/signifai/notify.sh signifaiTestApp $(uuidgen) $(date +%s) ERROR CRITICAL        \
                                     "testTag" testHealthRule $(uuidgen) 5 "HOST"                 \
                                     "testhost.signifai.io" $(uuidgen) 1                          \
                                     APPLICATION testConnectionThreshold $(uuidgen) 1             \
                                     APPLICATION javaApp $(uuidgen) TooManyConnections $(uuidgen) \
                                         GREATER_THAN BASELINE_PERCENTAGE true 85 95              \
                                     "Connection threshold violated" 353535 http://example.com/   \
                                     POLICY_OPEN_CRITICAL SignifAi 343434

echo "=== Test with custom(?) baseline, one evaluation, one condition ==="
sh custom/actions/signifai/notify.sh signifaiTestApp $(uuidgen) $(date +%s) ERROR CRITICAL        \
                                     "testTag" testHealthRule $(uuidgen) 5 "HOST"                 \
                                     "testhost.signifai.io" $(uuidgen) 1                          \
                                     APPLICATION testConnectionThreshold $(uuidgen) 1             \
                                     APPLICATION javaApp $(uuidgen) TooManyConnections $(uuidgen) \
                                         GREATER_THAN BASELINE_PERCENTAGE false                   \
                                           "ConnectionBaselinePercent" $(uuidgen) 85 95           \
                                     "Connection threshold violated" 353535 http://example.com/   \
                                     POLICY_OPEN_CRITICAL SignifAi 343434

echo "=== Test with not baseline, one evaluation, one condition ==="
sh custom/actions/signifai/notify.sh signifaiTestApp $(uuidgen) $(date +%s) ERROR CRITICAL        \
                                     "testTag" testHealthRule $(uuidgen) 5 "HOST"                 \
                                     "testhost.signifai.io" $(uuidgen) 1                          \
                                     APPLICATION testConnectionThreshold $(uuidgen) 1             \
                                     APPLICATION javaApp $(uuidgen) TooManyConnections $(uuidgen) \
                                         GREATER_THAN ABSOLUTE 85 95                              \
                                     "Connection threshold violated" 353535 http://example.com/   \
                                     POLICY_OPEN_CRITICAL SignifAi 343434