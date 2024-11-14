const { chromium } = require('@playwright/test');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  // Navigate to the URL passed as a command-line argument and wait until the network is idle
  // Since the first time you open the developer portal it will take time to provision the portal so it's
  // crucial to wait until the network is idle
  await page.goto(process.argv[2],{ waitUntil: 'networkidle' });
  const content = await page.content();
  //console.log(content);
  await browser.close();
})();
