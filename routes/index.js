
/*
 * GET home page.
 */

exports.admin = function(req, res){
  res.render('admin', { title: 'Admin' });
};

exports.index = function(req, res){
  res.render('index', { title: 'PodcastScience Live' });
};

exports.presentation = function(req, res){
  res.render('presentation', { title: 'PodcastScience Live' });
};
exports.presentationfull = function(req, res){
  res.render('presentationfull', { title: 'PodcastScience Live' });
};

exports.test = function(req, res){
  res.render('test', { title: 'PodcastScience Live' });
};