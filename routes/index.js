
/*
 * GET home page.
 */

exports.indexv2 = function(req, res){
  res.render('indexv2', { title: 'PodcastScience Live' });
};

exports.admin = function(req, res){
  res.render('admin', { title: 'Admin' });
};

exports.index = function(req, res){
  res.render('index', { title: 'PodcastScience Live' });
};