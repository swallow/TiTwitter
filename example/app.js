// open a single window
var window = Ti.UI.createWindow({
  backgroundColor:'white'
});
var label = Ti.UI.createLabel();
window.add(label);
window.open();

// TODO: write your module tests here
var titwitter = require('com.swllw.titwitter');
Ti.API.info("module is => " + titwitter);

if (titwitter.canTweetStatus) {
  titwitter.send('statuses/user_timeline', 'GET', {}, function(e) {
    if (e.success) {
      Ti.API.info(e.data);
    }
  });

  titwitter.send('statuses/update', 'POST', {status: 'Hello World'}, function(e) {
    if (e.success) {
      Ti.API.info('success');
    } else {
      alert(e);
    }
  });
}
