const wd = require('wd');
const assert = require('assert');

const opts = {
  port: 4723,
  capabilities: {
    platformName: process.env.DEVICEFARM_DEVICE_PLATFORM_NAME,
    platformVersion: process.env.DEVICEFARM_DEVICE_OS_VERSION,
    deviceName: process.env.DEVICEFARM_DEVICE_NAME,
    app: process.env.DEVICEFARM_APP_PATH,
    automationName: 'UiAutomator2',
  }
};

async function runTest() {
  const driver = wd.promiseChainRemote(opts);

  try {
    await driver.init(opts.capabilities);
    console.log('App started');

    // Wait for app to load
    await driver.sleep(5000);

    // Add your test steps here
    const element = await driver.elementByXPath('//android.widget.Button[@text="Click Me"]');
    await element.click();

    // Verify results
    const result = await driver.elementByXPath('//android.widget.TextView[@text="Clicked!"]');
    assert(await result.isDisplayed(), 'Result text should be visible');

    console.log('Test passed!');
  } catch (error) {
    console.error('Test failed:', error);
    throw error;
  } finally {
    await driver.quit();
  }
}

runTest().catch(console.error);
