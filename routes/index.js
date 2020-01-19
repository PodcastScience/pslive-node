
/*
 * GET home page.
 */

exports.admin = function(req, res){
  res.render('admin', { title: 'Admin' });
};

exports.index = function(req, res){
  res.render('index', { title: 'PodcastScience Live' });
};

exports.video = function(req, res){
  res.render('video', { title: 'PodcastScience Live' });
};

exports.presentation = function(req, res){
  res.render('presentation', { title: 'PodcastScience Live' });
};
exports.presentationfull = function(req, res){
  res.render('presentationfull', { title: 'PodcastScience Live' });
};