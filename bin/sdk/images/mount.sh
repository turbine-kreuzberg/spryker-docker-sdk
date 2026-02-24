#!/usr/bin/env bash

import sdk/images/common.sh

function Images::computeBuildHash() {
    bash "$(dirname "${BASH_SOURCE[0]}")/compute-hash.sh" "${DEPLOYMENT_PATH}"
}

function Images::getAppBuildTag() {
    local buildHash
    buildHash=$(Images::computeBuildHash)
    echo -n "${SPRYKER_DOCKER_PREFIX}_app_build:${SPRYKER_DOCKER_TAG}-${buildHash}"
}

function Images::areApplicationImagesBuilt() {
    Console::start "Checking application images are built..."

    local buildTag
    buildTag=$(Images::getAppBuildTag)

    if docker image inspect "${buildTag}" >/dev/null 2>&1; then
        Console::end "[BUILT]"
        return "${TRUE}"
    fi

    return "${FALSE}"
}

function Images::getFrontendBuildTag() {
    local buildHash
    buildHash=$(Images::computeBuildHash)
    echo -n "${SPRYKER_DOCKER_PREFIX}_frontend_build:${SPRYKER_DOCKER_TAG}-${buildHash}"
}

function Images::areFrontendImagesBuilt() {
    Console::start "Checking frontend images are built..."

    local buildTag
    buildTag=$(Images::getFrontendBuildTag)

    if docker image inspect "${buildTag}" >/dev/null 2>&1; then
        Console::end "[BUILT]"
        return "${TRUE}"
    fi

    return "${FALSE}"
}

function Images::buildApplication() {
    local force=''
    for arg in "${@}"; do
        case "${arg}" in
            '--force')
                force=1
                ;;
            '--no-cache')
                ;;
            *)
                Console::verbose "\nUnknown option ${INFO}${arg}${WARN} is acquired for Images::buildApplication."
                ;;
        esac
    done

    if [ -z "${force}" ] && Images::areApplicationImagesBuilt; then
        local baseRunApp="${SPRYKER_DOCKER_PREFIX}_run_app:${SPRYKER_DOCKER_TAG}"
        for application in "${SPRYKER_APPLICATIONS[@]}"; do
            Images::_tagByApp "${application}" "${baseRunApp}" "${baseRunApp}"
        done
        return "${TRUE}"
    fi

    Images::_buildApp mount
    Images::tagApplications "${SPRYKER_DOCKER_TAG}"

    local runtimeCliImage="${SPRYKER_DOCKER_PREFIX}_run_cli:${SPRYKER_DOCKER_TAG}"
    local buildTag
    buildTag=$(Images::getAppBuildTag)
    docker tag "${runtimeCliImage}" "${buildTag}"
}

function Images::buildFrontend() {
    local force=''
    for arg in "${@}"; do
        case "${arg}" in
            '--force')
                force=1
                ;;
            '--no-cache')
                ;;
            *)
                Console::verbose "\nUnknown option ${INFO}${arg}${WARN} is acquired for Images::buildFrontend."
                ;;
        esac
    done

    if [ -z "${force}" ] && Images::areFrontendImagesBuilt; then
        return "${TRUE}"
    fi

    Images::_buildFrontend mount
    Images::_buildGateway
    Images::tagFrontend "${SPRYKER_DOCKER_TAG}"

    local runtimeFrontendImage="${SPRYKER_DOCKER_PREFIX}_run_frontend:${SPRYKER_DOCKER_TAG}"
    local buildTag
    buildTag=$(Images::getFrontendBuildTag)
    docker tag "${runtimeFrontendImage}" "${buildTag}"
}
