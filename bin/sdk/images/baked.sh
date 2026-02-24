#!/usr/bin/env bash

import sdk/images/common.sh

function Images::getAppBuildTag() {
    echo -n "${SPRYKER_DOCKER_PREFIX}_app_build:${SPRYKER_DOCKER_TAG}-${SPRYKER_REPOSITORY_HASH}"
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
    echo -n "${SPRYKER_DOCKER_PREFIX}_frontend_build:${SPRYKER_DOCKER_TAG}-${SPRYKER_REPOSITORY_HASH}"
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
        return "${TRUE}"
    fi

    Images::_buildApp baked
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

    Images::_buildFrontend baked
    Images::_buildGateway
    Images::tagFrontend "${SPRYKER_DOCKER_TAG}"

    local runtimeFrontendImage="${SPRYKER_DOCKER_PREFIX}_run_frontend:${SPRYKER_DOCKER_TAG}"
    local buildTag
    buildTag=$(Images::getFrontendBuildTag)
    docker tag "${runtimeFrontendImage}" "${buildTag}"
}
