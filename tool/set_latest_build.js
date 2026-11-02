// F18.21: yayınlanan Release'in derleme numarasını `config/app`a yazar
// (uygulama "Yeni sürüm var" der). CI `release` işi çağırır:
//   node tool/set_latest_build.js <build> <name>
// Kimlik: GOOGLE_APPLICATION_CREDENTIALS (hizmet hesabı). `config/` istemciye
// salt okunur (firestore.rules); yönetici SDK'sı kuralları atlar.
const path = require('path');
const admin = require(path.join(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'));

const build = parseInt(process.argv[2], 10);
const name = process.argv[3] || '';
if (!Number.isInteger(build) || build <= 0) {
  console.error('Geçersiz derleme numarası:', process.argv[2]);
  process.exit(1);
}
admin.initializeApp();
admin
  .firestore()
  .collection('config')
  .doc('app')
  .set({ latestBuild: build, latestName: name }, { merge: true })
  .then(() => console.log(`config/app.latestBuild = ${build} (${name})`))
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
