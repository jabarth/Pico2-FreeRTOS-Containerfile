FROM ubuntu:24.04 AS picotool
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    cmake \
    gcc-arm-none-eabi \
    libnewlib-arm-none-eabi \
    libstdc++-arm-none-eabi-newlib \
    build-essential \
    git \
    python3 \
    python3-pip \
    python3-venv \
    libusb-1.0-0-dev \
    pkg-config

RUN git clone https://github.com/raspberrypi/pico-sdk /pico-sdk && \
    cd /pico-sdk && \
    git submodule update --init

ENV PICO_SDK_PATH=/pico-sdk

RUN git clone https://github.com/raspberrypi/picotool /picotool-src && \
    cd /picotool-src && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    mkdir -p /usr/local/bin/ && \
    cp picotool /usr/local/bin/picotool && \
    rm -rf /picotool-src && \
    /usr/local/bin/picotool version


FROM picotool:latest AS freertos-builder
WORKDIR /app

RUN mkdir -p src config lib

RUN cd lib && \
    git clone https://github.com/FreeRTOS/FreeRTOS-Kernel && \
    git clone https://github.com/FreeRTOS/FreeRTOS-Kernel-Community-Supported-Ports

RUN cat <<'EOF' > CMakeLists.txt
cmake_minimum_required(VERSION 3.12)
set(NAME morse-blink)
set(PICO_BOARD pico2)
set(PICO_PLATFORM rp2350)
include($ENV{PICO_SDK_PATH}/external/pico_sdk_import.cmake)
project(${NAME} C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
pico_sdk_init()
# FreeRTOS setup (using community port's CMakeLists.txt)
set(FREERTOS_KERNEL_PATH ${CMAKE_CURRENT_LIST_DIR}/lib/FreeRTOS-Kernel)
set(FREERTOS_COMMUNITY_PATH ${CMAKE_CURRENT_LIST_DIR}/lib/FreeRTOS-Kernel-Community-Supported-Ports)
set(FREERTOS_PORT_PATH ${FREERTOS_COMMUNITY_PATH}/GCC/RP2350_ARM_NTZ)
set(FREERTOS_CONFIG_FILE_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/config)
add_subdirectory(${FREERTOS_PORT_PATH} FreeRTOS-Kernel-Port)
add_executable(${NAME}
    src/main.c
)
target_link_libraries(${NAME}
    pico_stdlib
    FreeRTOS-Kernel # Main FreeRTOS port
    FreeRTOS-Kernel-Heap4 # Or another heap, e.g., -Heap1
    # FreeRTOS-Kernel-Static # Uncomment if using static allocation
)
pico_add_extra_outputs(${NAME})
EOF

RUN cat <<'EOF' > config/FreeRTOSConfig.h
#ifndef FREERTOS_CONFIG_H
#define FREERTOS_CONFIG_H
/* RP2350 specific */
#define configSUPPORT_PICO_SYNC_INTEROP 1
#define configSUPPORT_PICO_TIME_INTEROP 1
#define configENABLE_FPU 1
#define configENABLE_MPU 0
#define configENABLE_TRUSTZONE 0
#define configRUN_FREERTOS_SECURE_ONLY 1
#define configUSE_PREEMPTION 1
#define configUSE_PORT_OPTIMISED_TASK_SELECTION 0
#define configUSE_TICKLESS_IDLE 0
#define configCPU_CLOCK_HZ (133000000)
#define configTICK_RATE_HZ 1000
#define configMAX_PRIORITIES 5
#define configMINIMAL_STACK_SIZE 128
#define configMAX_TASK_NAME_LEN 16
#define configUSE_16_BIT_TICKS 0
#define configIDLE_SHOULD_YIELD 1
#define configUSE_MUTEXES 0
#define configUSE_RECURSIVE_MUTEXES 0
#define configUSE_COUNTING_SEMAPHORES 0
#define configUSE_ALTERNATIVE_API 0
#define configQUEUE_REGISTRY_SIZE 10
#define configUSE_QUEUE_SETS 0
#define configUSE_TIME_SLICING 0
#define configUSE_NEWLIB_REENTRANT 0
#define configENABLE_BACKWARD_COMPATIBILITY 0
#define configNUM_THREAD_LOCAL_STORAGE_POINTERS 5
#define configSTACK_DEPTH_TYPE uint16_t
#define configMESSAGE_BUFFER_LENGTH_TYPE size_t
/* Memory allocation related definitions. */
#define configSUPPORT_STATIC_ALLOCATION 0
#define configSUPPORT_DYNAMIC_ALLOCATION 1
#define configTOTAL_HEAP_SIZE 12000
#define configAPPLICATION_ALLOCATED_HEAP 0
#define configSTACK_ALLOCATION_FROM_SEPARATE_HEAP 0
/* Hook function related definitions. */
#define configUSE_IDLE_HOOK 0
#define configUSE_TICK_HOOK 0
#define configCHECK_FOR_STACK_OVERFLOW 0
#define configUSE_MALLOC_FAILED_HOOK 0
#define configUSE_DAEMON_TASK_STARTUP_HOOK 0
#define configUSE_SB_COMPLETED_CALLBACK 0
/* Run time and task stats gathering related definitions. */
#define configGENERATE_RUN_TIME_STATS 0
#define configUSE_TRACE_FACILITY 0
#define configUSE_STATS_FORMATTING_FUNCTIONS 0
/* Co-routine related definitions. */
#define configUSE_CO_ROUTINES 0
#define configMAX_CO_ROUTINE_PRIORITIES 1
/* Software timer related definitions. */
#define configUSE_TIMERS 1
#define configTIMER_TASK_PRIORITY 3
#define configTIMER_QUEUE_LENGTH 10
#define configTIMER_TASK_STACK_DEPTH configMINIMAL_STACK_SIZE
/* Interrupt nesting behaviour configuration. */
#define configKERNEL_INTERRUPT_PRIORITY 255
#define configMAX_SYSCALL_INTERRUPT_PRIORITY 16
#define configMAX_API_CALL_INTERRUPT_PRIORITY 16
/* SMP cores. */
#define configNUMBER_OF_CORES 2
#define configTICK_CORE 0
#define configRUN_MULTIPLE_PRIORITIES 1 // Optimized for SMP scheduling
#define configUSE_CORE_AFFINITY 1
#define configMAX_PRIORITIES_PER_CORE 5 // Match max priorities
/* Define to trap errors during development. */
#define configASSERT(x) if ((x) == 0) {for (;;) {}}
/* FreeRTOS MPU specific definitions. */
#define configINCLUDE_APPLICATION_DEFINED_PRIVILEGED_FUNCTIONS 0
#define configTOTAL_MPU_REGIONS 8 /* Default value. */
#define configTEX_S_C_B_FLASH 0x07UL /* Default value. */
#define configTEX_S_C_B_SRAM 0x07UL /* Default value. */
#define configENFORCE_SYSTEM_CALLS_FROM_KERNEL_ONLY 1
#define configALLOW_UNPRIVILEGED_CRITICAL_SECTIONS 0
#define configUSE_TASK_NOTIFICATIONS 1
#define configRECORD_STACK_HIGH_ADDRESS 1
#define configUSE_PASSIVE_IDLE_HOOK 1
/* Optional functions - most linkers will remove unused functions anyway. */
#define INCLUDE_vTaskPrioritySet 1
#define INCLUDE_uxTaskPriorityGet 1
#define INCLUDE_vTaskDelete 1
#define INCLUDE_vTaskSuspend 1
#define INCLUDE_xResumeFromISR 1
#define INCLUDE_vTaskDelayUntil 1
#define INCLUDE_vTaskDelay 1
#define INCLUDE_xTaskGetSchedulerState 1
#define INCLUDE_xTaskGetCurrentTaskHandle 1
#define INCLUDE_uxTaskGetStackHighWaterMark 0
#define INCLUDE_xTaskGetIdleTaskHandle 0
#define INCLUDE_eTaskGetState 0
#define INCLUDE_xEventGroupSetBitsFromISR 1 // Fixed: plural "Bits" for SMP inter-core sync
#define INCLUDE_xTimerPendFunctionCall 1 // Required for xEventGroupSetBitsFromISR in SMP
#define INCLUDE_xTaskAbortDelay 0
#define INCLUDE_xTaskGetHandle 0
#define INCLUDE_xTaskResumeFromISR 1
/* A header file that defines trace macro can be included here. */
#endif /* FREERTOS_CONFIG_H */
EOF

RUN cat <<'EOF' > src/main.c
#include "FreeRTOS.h"
#include "task.h"
#include "pico/stdlib.h"
#define LED_PIN 25
#define UNIT_MS 200 // Base unit for morse timing (dot duration)
static const char *morse_codes[26] = {
    ".-", "-...", "-.-.", "-..", ".", "..-.", "--.", "....", "..", // a-i
    ".---", "-.-", ".-..", "--", "-.", "---", ".--.", "--.-", ".-.", // j-r
    "...", "-", "..-", "...-", ".--", "-..-", "-.--", "--.." // s-z
};
static const char *message = "hello world ";
void vApplicationPassiveIdleHook(void) {
    // Stub for passive idle on secondary core; add sleep/low-power code if needed
}
static void send_morse_char(char c) {
    if (c == ' ') {
        vTaskDelay(pdMS_TO_TICKS(7 * UNIT_MS)); // Space between words
        return;
    }
    if (c < 'a' || c > 'z') return;
    const char *code = morse_codes[c - 'a'];
    while (*code) {
        gpio_put(LED_PIN, 1); // LED on
        if (*code == '.') {
            vTaskDelay(pdMS_TO_TICKS(UNIT_MS)); // Dot
        } else {
            vTaskDelay(pdMS_TO_TICKS(3 * UNIT_MS)); // Dash
        }
        gpio_put(LED_PIN, 0); // LED off
        vTaskDelay(pdMS_TO_TICKS(UNIT_MS)); // Gap between elements
        code++;
    }
    vTaskDelay(pdMS_TO_TICKS(3 * UNIT_MS)); // Gap between letters
}
static void blink_task(void *pvParameters) {
    while (true) {
        for (const char *p = message; *p; p++) {
            send_morse_char(*p);
        }
    }
}
int main() {
    stdio_init_all();
    gpio_init(LED_PIN);
    gpio_set_dir(LED_PIN, GPIO_OUT);
    xTaskCreate(blink_task, "Blink Task", 256, NULL, 1, NULL);
    vTaskStartScheduler();
    // Should never reach here
    while (1);
    return 0;
}
EOF

RUN mkdir build && \
    cd build && \
    cmake -DPICOTOOL_EXECUTABLE=/usr/local/bin/picotool .. && \
    make -j$(nproc)

FROM scratch AS freertos-firmware-uf2
COPY --from=freertos-builder:latest /app/build/morse-blink.uf2 /firmware.uf2