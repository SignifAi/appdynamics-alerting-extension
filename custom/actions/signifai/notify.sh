#!/bin/bash

# Provide the parameter names in the order that they are provided. 
# BASE_ARGS is the overarching argument list, but processing shifts
# when NUMBER_OF_EVALUATION_ENTITIES is hit. At that point it starts
# evaluating for EVALUATION_ENTITY_ARGS for n in $NUMBER_OF_EVALUATION_ENTITIES
# sets of arguments. Once all of those argument sets are finished, it will
# move on to SUMMARY_MESSAGE and so on. 
BASE_ARGS="APP_NAME APP_ID PVN_ALERT_TIME PRIORITY SEVERITY TAG HEALTH_RULE_NAME \
      HEALTH_RULE_ID PVN_TIME_PERIOD_IN_MINUTES AFFECTED_ENTITY_TYPE \
      AFFECTED_ENTITY_NAME AFFECTED_ENTITY_ID NUMBER_OF_EVALUATION_ENTITIES \
      SUMMARY_MESSAGE INCIDENT_ID DEEP_LINK_URL EVENT_TYPE ACCOUNT_NAME \
      ACCOUNT_ID"

# Same as BASE_ARGS, but this is the argument set for an evaluation entity.
# Once NUMBER_OF_TRIGGERED_CONDITIONS_PER_EVALUATION_ENTITY is reached, it
# starts evaluating for TRIGGERED_CONDITION_ARGS for n in 
# $NUMBER_OF_TRIGGERED_CONDITIONS_PER_EVALUATION_ENTITY sets of arguments.
# For now, unlike BASE_ARGS, we stop after evaluating the triggered conditions
# per evaluation entity, but adding arguments to this list will continue
# processing those as well, since it's the same mechanism over this set
# of data instead. 
# However, we will suffix the index of the evaluation entity to each of these
# names. So EVALUATION_ENTITY_TYPE will actually be EVALUATION_ENTITY_TYPE_0
# for the first element, etc.
EVALUATION_ENTITY_ARGS="EVALUATION_ENTITY_TYPE EVALUATION_ENTITY_NAME \
                        EVALUATION_ENTITY_ID \
                        NUMBER_OF_TRIGGERED_CONDITIONS_PER_EVALUATION_ENTITY"

# See above, but the argument set for a triggered condition for an evaluation
# entity. 
TRIGGERED_CONDITION_ARGS="SCOPE_TYPE SCOPE_NAME SCOPE_ID CONDITION_NAME \
                          CONDITION_ID OPERATOR CONDITION_UNIT_TYPE \
                          THRESHOLD_VALUE OBSERVED_VALUE"

TC_BASELINE_ARGS="USE_DEFAULT_BASELINE BASELINE_NAME BASELINE_ID"

# Gather args into their variables
for arg in $BASE_ARGS; do
	printf -v "$arg" %s "${1//\"/\\\"}"
	shift
	if [ "$arg" == "NUMBER_OF_EVALUATION_ENTITIES" ]; then
		[ -z "$NUMBER_OF_EVALUATION_ENTITIES" ] && NUMBER_OF_EVALUATION_ENTITIES=0
		if [ $NUMBER_OF_EVALUATION_ENTITIES -gt 0 ]; then
			for i in $(seq 1 $NUMBER_OF_EVALUATION_ENTITIES); do
				for ee_arg in $EVALUATION_ENTITY_ARGS; do
					ee_idx=$(($i-1))
					ee_var="${ee_arg}_${ee_idx}"
					printf -v "$ee_var" %s "${1//\"/\\\"}"
					shift
					if [ "$ee_arg" == "NUMBER_OF_TRIGGERED_CONDITIONS_PER_EVALUATION_ENTITY" ]; then
						NTCPEE_var="${ee_arg}_${ee_idx}"
						[ -z "${!NTCPEE_var}" ] && printf -v $NTCPEE_var %d 0
						if [ ${!NTCPEE_var} -gt 0 ]; then
							for j in $(seq 1 ${!NTCPEE_var}); do
								for tc_arg in $TRIGGERED_CONDITION_ARGS; do
									tc_idx=$(($j-1))
									tc_var="${tc_arg}_${ee_idx}_${tc_idx}"
									printf -v "$tc_var" %s "${1//\"/\\\"}"
									shift
									if [ "$tc_arg" == "CONDITION_UNIT_TYPE" ]; then
										for tcb_arg in $TC_BASELINE_ARGS; do
											tcb_var="${tcb_arg}_${ee_idx}_${tc_idx}"
											if [ "${!tc_var:0:9}" == "BASELINE_" ]; then
												udb_var="USE_DEFAULT_BASELINE_${ee_idx}_${tc_idx}"
												if [ "${tcb_arg}" == "USE_DEFAULT_BASELINE" -o                                \
												     \( "${!udb_var}" == "false" -a                                           \
												       \( "${tcb_arg}" == "BASELINE_NAME" -o "${tcb_arg}" == "BASELINE_ID" \) \
												     \)                                                                       \
												   ]; then
													printf -v "$tcb_var" %s "${1//\"/\\\"}"
													shift
												else
													printf -v "$tcb_var" %s ""
												fi
											fi
										done
									fi
								done
							done
						fi
					fi
				done
			done
		fi
	fi
done

REGEX=$(echo "^(${BASE_ARGS// /|}|${EVALUATION_ENTITY_ARGS// /|}|${TRIGGERED_CONDITION_ARGS// /|}|${TC_BASELINE_ARGS// /|})" | sed -E 's:\|{2,}:|:g')
declare | grep -E "$REGEX"


