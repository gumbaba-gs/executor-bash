#!/usr/bin/env bash
[[ -n "${AUTOMATION_DEBUG}" ]] && set ${AUTOMATION_DEBUG}
trap '[[ (-z "${AUTOMATION_DEBUG}") ; exit 1' SIGHUP SIGINT SIGTERM
. "${AUTOMATION_BASE_DIR}/common.sh"

# Get the generation context so we can run template generation
. "${GENERATION_BASE_DIR}/execution/setContext.sh"

tmpdir="$(getTempDir "cota_inf_XXX")"

data_manifest_filename="cot_data_file_manifest.json"

function main() {
    info "Building Deployment ${DEPLOYMENT_UNIT_LIST}"
    for DEPLOYMENT_UNIT in ${DEPLOYMENT_UNIT_LIST[0]}; do

        DEPLOYMENT_GROUP="${DEPLOYMENT_GROUP:-"application"}"

         # Generate a build blueprint so that we can find out the source S3 bucket
        info "Generating blueprint to find details..."
        ${GENERATION_DIR}/createTemplate.sh -e "buildblueprint" -p "aws" -l "${DEPLOYMENT_GROUP}" -u "${DEPLOYMENT_UNIT}" -o "${tmpdir}" > /dev/null
        BUILD_BLUEPRINT="${tmpdir}/buildblueprint-${DEPLOYMENT_GROUP}-${DEPLOYMENT_UNIT}-config.json"

        if [[ ! -f "${BUILD_BLUEPRINT}" || -z "$(cat ${BUILD_BLUEPRINT} )" ]]; then
            fatal "Could not generate blueprint for task details"
            return 255
        fi

        mkdir -p "${tmpdir}/${DEPLOYMENT_UNIT}"
        data_manifest_file="${tmpdir}/${DEPLOYMENT_UNIT}/${data_manifest_filename}"

        dataset_master_location="$( jq -r '.Occurrence.State.Attributes.DATASET_MASTER_LOCATION' < "${BUILD_BLUEPRINT}" )"
        dataset_prefix="$( jq -r '.Occurrence.State.Attributes.DATASET_PREFIX' < "${BUILD_BLUEPRINT}" )"
        master_data_bucket_name="$( jq -r '.Occurrence.State.Attributes.NAME' < "${BUILD_BLUEPRINT}" )"
        dataset_region="$( jq -r '.Occurrence.State.Attributes.REGION' < "${BUILD_BLUEPRINT}" )"

        info "Generating master data reference from bucket: ${master_data_bucket_name} - prefix: ${dataset_prefix}"
        aws --region "${dataset_region}" s3api list-objects-v2 --bucket "${master_data_bucket_name}" --prefix "${dataset_prefix}" --query 'Contents[*].{Key:Key,ETag:ETag,LastModified:LastModified}' > "${data_manifest_file}" || return $?

        if [[ -f "${data_manifest_file}" ]]; then

            build_reference="$( shasum -a 1 "${data_manifest_file}" | cut -d " " -f 1  )"
            save_context_property CODE_COMMIT_LIST "${build_reference}"
            save_context_property S3_DATA_STAGE "${dataset_master_location}"

            save_chain_property GIT_COMMIT "${build_reference}"

            cp "${data_manifest_file}" "${AUTOMATION_BUILD_SRC_DIR}/${data_manifest_filename}"

            info "Commit: ${build_reference}"

        else
            fatal "Could not generate data manifest file or no files could be found"
            return 128
        fi

    done

    return 0
}

main "$@"
