#!/bin/bash

# printf -v requires bash >= 3.1

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
#declare | grep -E "$REGEX"

JSON_FILE=$(mktemp)
if [ $? -ne 0 ]; then
	echo "Couldn't safely create tempfile"
	exit 1
fi

cat - > $JSON_FILE <<END_OF_CHUNK
{
    "version": 3,
    "account": {
        "id": "${ACCOUNT_ID}",
        "name": "${ACCOUNT_NAME}"
    },
    "health_rule": {
        "id": "${HEALTH_RULE_ID}",
        "name": "${HEALTH_RULE_NAME}",
        "duration": "${PVN_TIME_PERIOD_IN_MINUTES}"
    },
    "affected_entity": {
        "type": "${AFFECTED_ENTITY_TYPE}",
        "name": "${AFFECTED_ENTITY_NAME}",
        "id": "${AFFECTED_ENTITY_ID}"
    },
    "application": {
        "name": "${APP_NAME}",
        "id": "${APP_ID}",
    },
    "alert": {
        "time": "${PVN_ALERT_TIME}",
        "tag": "${TAG}"
    },
    "summary_message": "${SUMMARY_MESSSAGE}",
    "incident_id": "${INCIDENT_ID}",
    "deep_link_url": "${DEEP_LINK_URL}",
    "event_type": "${EVENT_TYPE}",
    "priority": "${PRIORITY}",
    "severity": "${SEVERITY}",
    "evaluation_entities_number": "${NUMBER_OF_EVALUATION_ENTITIES}",
    "evaluation_entities": [
END_OF_CHUNK

deref_ee() {
	ACCESS_VAR="$1_$2"
	echo "${!ACCESS_VAR}"
}

deref_tc() {
	ACCESS_VAR="$1_$2_$3"
	echo "${!ACCESS_VAR}"
}

for i in $(seq 1 ${NUMBER_OF_EVALUATION_ENTITIES}); do
	ee_idx=$(($i-1))

	cat - >> $JSON_FILE <<END_OF_CHUNK
        {
            "type": "$(deref_ee EVALUATION_ENTITY_TYPE $ee_idx)",
            "name": "$(deref_ee EVALUATION_ENTITY_NAME $ee_idx)",
            "id": "$(deref_ee EVALUATION_ENTITY_ID $ee_idx)",
            "triggered_conditions_number": "$(deref_ee NUMBER_OF_TRIGGERED_CONDITIONS_PER_EVALUATION_ENTITY $ee_idx)",
            "triggered_conditions": [
END_OF_CHUNK
    ee_tc_cnt_acc="NUMBER_OF_TRIGGERED_CONDITIONS_PER_EVALUATION_ENTITY_${ee_idx}"
    for j in $(seq 1 ${!ee_tc_cnt_acc}); do
    	tc_idx=$(($i-1))
    	cat - >> $JSON_FILE <<END_OF_CHUNK
                {
                    "scope_type": "$(deref_tc SCOPE_TYPE $ee_idx $tc_idx)",
                    "scope_name": "$(deref_tc SCOPE_NAME $ee_idx $tc_idx)",
                    "scope_id": "$(deref_tc SCOPE_ID $ee_idx $tc_idx)",
                    "condition_name": "$(deref_tc CONDITION_NAME $ee_idx $tc_idx)",
                    "condition_id": "$(deref_tc CONDITION_ID $ee_idx $tc_idx)",
                    "operator": "$(deref_tc OPERATOR $ee_idx $tc_idx)",
                    "condition_unit_type": "$(deref_tc CONDITION_UNIT_TYPE $ee_idx $tc_idx)",
                    "use_default_baseline": "$(deref_tc USE_DEFAULT_BASELINE $ee_idx $tc_idx)",
END_OF_CHUNK
		if [ "$(deref_tc USE_DEFAULT_BASELINE $ee_idx $tc_idx)" == "false" ]; then
			cat - >> $JSON_FILE <<END_OF_CHUNK
                    "baseline_name": "$(deref_tc BASELINE_NAME $ee_idx $tc_idx)",
                    "baseline_id": "$(deref_tc BASELINE_ID $ee_idx $tc_idx)",
END_OF_CHUNK
		fi

		cat - >> $JSON_FILE <<END_OF_CHUNK
                    "threshold_value": "$(deref_tc THRESHOLD_VALUE $ee_idx $tc_idx)",
                    "observed_value": "$(deref_tc OBSERVED_VALUE $ee_idx $tc_idx)"
END_OF_CHUNK
		if [ $j -lt ${!ee_tc_cnt_acc} ]; then
			cat - >> $JSON_FILE <<END_OF_CHUNK
                },
END_OF_CHUNK
		else
			cat - >> $JSON_FILE <<END_OF_CHUNK
                }
END_OF_CHUNK
		fi
	done
	cat - >> $JSON_FILE <<END_OF_CHUNK
            ]
END_OF_CHUNK
	if [ $i -lt ${NUMBER_OF_EVALUATION_ENTITIES} ]; then
		cat - >> $JSON_FILE <<END_OF_CHUNK
        },
END_OF_CHUNK
	else
		cat - >> $JSON_FILE <<END_OF_CHUNK
        }
END_OF_CHUNK
	fi
	cat - >> $JSON_FILE <<END_OF_CHUNK
    ]
END_OF_CHUNK
done

cat - >> $JSON_FILE <<END_OF_CHUNK
}
END_OF_CHUNK

cat $JSON_FILE
rm $JSON_FILE
