// ============================================================
//  Helper
// ============================================================
function parseNum(s) {
  return Number(String(s).replace(/,/g, "").replace(/\s/g, "")) || 0;
}
 
function fmtMoney(n) {
  return "$" + Math.floor(Math.abs(n)).toLocaleString("en-US");
}
 
// ============================================================
//  POST /tracker — รับข้อมูลจาก Roblox
// ============================================================
app.post("/tracker", (req, res) => {
  const { username, displayName, money } = req.body;
 
  const result = {
    username: username || null,
    displayName: displayName || null,
    money: parseNum(money),
    moneyFormatted: fmtMoney(parseNum(money)),
  };
 
  console.log(`[${new Date().toLocaleTimeString()}]`);
  console.log(`  👤 Username    : ${result.username}`);
  console.log(`  🏷️  DisplayName : ${result.displayName}`);
  console.log(`  💰 Money       : ${result.moneyFormatted}`);
  console.log("─".repeat(40));
 
  res.json(result);
});