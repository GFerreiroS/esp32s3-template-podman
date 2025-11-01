#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"

extern "C" void app_main(void) {
    const char* TAG = "app";
    while (true) {
        ESP_LOGI(TAG, "Hello from ESP-IDF (C++)!");
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
