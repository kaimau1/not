// URETILDI: python tool/gen_font_sources.py <google_fonts-8.2.0>. Elle duzenleme.
// Her kayit: agirlik, SHA-256 (adres = fonts.gstatic.com/s/a/<sha>.ttf), uzunluk.

typedef FontSource = ({int weight, String sha256, int length});

const Map<String, List<FontSource>> kDownloadableFontSources = {
  'Open Sans': [
    (weight: 400, sha256: '5af20f022c70222f0e960f45a033366eb2582c982031a715f9cafc05acbc51a5', length: 98532),
    (weight: 500, sha256: '5a420b44a9efa533fe670589230b4a68b40ff2c7a414f6c0323b160b5d29e264', length: 98676),
  ],
  'Lato': [
    (weight: 400, sha256: '5ced1045820caaac87af3f61ded09bacc90881f158d04c59dcce436fd02ad368', length: 33408),
  ],
  'Source Sans 3': [
    (weight: 400, sha256: 'f63ee6981c8ca18a461f39ca0475668d26f9897b064a33b7448a4352e3281edc', length: 234684),
    (weight: 500, sha256: 'f709a664f7810c42bd46e595904bb44500b4272235a9143e43ec586a765450d4', length: 234472),
  ],
  'Work Sans': [
    (weight: 400, sha256: '4e3f7658c0730039e4c170dc038292141b9ac48df1732c335200391b072d6599', length: 114120),
    (weight: 500, sha256: '771c56ba0b70f89a2edceacc63366964e696ed08a4db18a4d6af15bb6ed8318b', length: 114588),
  ],
  'Rubik': [
    (weight: 400, sha256: 'db4588883899babda86dc335c84b4876cd9afaedcd845830e9ac4d11c7fbed97', length: 174968),
    (weight: 500, sha256: '9876a66820c1b56a1b2a7d03cab864a17f1eed5e05bf7027fde46cd4305d2ea5', length: 175572),
  ],
  'Nunito': [
    (weight: 400, sha256: '33383e64e1f3603142b718d1854778a9c9c5e2744b5aafdac2b66fedde54a98d', length: 125504),
    (weight: 500, sha256: '578b7f3f76615d258788124d9299d5fcef1711101cee45c494cc985a9d736c4e', length: 125628),
  ],
  'Montserrat': [
    (weight: 400, sha256: '7ec20755dbe4985c2505b42bbdfcf2456dd0f2acd8801d9725b2c82c9f9b6433', length: 175484),
    (weight: 500, sha256: '36ad36e0941cc29d47c926ee87d664c5dd20ecebe75410843e05a3bec763fb70', length: 175452),
  ],
  'Poppins': [
    (weight: 400, sha256: '2dd6eb23c4972b346197d272c4e2479b89ed240ece4d2b0e0cd89f0c1caa2710', length: 154628),
    (weight: 500, sha256: 'c0ba5609d6562c76ab7db73fa9c9b283d210598cb318a45d4085f540e4753d60', length: 152860),
  ],
  'Merriweather': [
    (weight: 400, sha256: 'a05a93f3e8c90b815dbecae2f7cc3973dd5100a2494d3f2546cb4d3ef4f94c8a', length: 585952),
    (weight: 500, sha256: '49945dd5c14d52a34bcfcb07f7f9f4638d4f1be4a994aebe0155e5d3878076c1', length: 585996),
  ],
  'PT Serif': [
    (weight: 400, sha256: '0638ef6b9c547faff0b143e0668bc997224f5fc73e797f5055e39e29c6e2b004', length: 78696),
  ],
  'EB Garamond': [
    (weight: 400, sha256: '819316ad1be484e76ced5b6d58682e6a476116d26e5eb236cc8615d227080ffc', length: 446108),
    (weight: 500, sha256: '441d45e6797db8b91d3eb0527adf96d27d4a94bc4a7025e8ba787e84dc13164d', length: 448388),
  ],
  'Playfair Display': [
    (weight: 400, sha256: '775cd3f92411b97cc374e0d8909c5caf3713508120866dc62b08f7a20213ba6d', length: 123216),
    (weight: 500, sha256: '102a056af74fd12dd9436188b5c3bf72aa6e7e1ae55223d4e6cd76652edff492', length: 123584),
  ],
  'JetBrains Mono': [
    (weight: 400, sha256: 'fc34426314d00825ccc768a0c4b1178fe704f04bd947882ef10c2b71b7e355e7', length: 112148),
    (weight: 500, sha256: 'ba10286722bd7dc2274b817575046e39ee816d6ba1e2ace48e22bcd068576941', length: 112180),
  ],
  'Patrick Hand': [
    (weight: 400, sha256: '309ba7d5200f03efa6c3d747d7ad47a5a354464ae0a6ffcb02c747286bc50964', length: 81712),
  ],
};
