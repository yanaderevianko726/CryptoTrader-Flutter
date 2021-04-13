import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter/services.dart';

class ImportIndicator extends StatefulWidget{
  ImportIndicator(this.index, );
  final index;

  @override
  ImportIndicatorState createState() => new ImportIndicatorState();
}

class ImportIndicatorState extends State<ImportIndicator> {
  Uint8List uint8listBytes;
  BMP332Header header;
  Random r = Random();

  @override
  void initState() {
    super.initState();

    header = BMP332Header(100, 100);
    // uint8listBytes = header.appendBitmap(
    //     Uint8List.fromList(List<int>.generate(10000, (i) => r.nextInt(255))));
    // _getData();
    _readFileByte();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        color: Colors.red,
        child: Center(
          child: Container(
            width: double.infinity, height: 240,
            color: Colors.white,
            child: uint8listBytes == null ? Container() : Image.memory(uint8listBytes, width: 120, height: 120, fit: BoxFit.fill,),
          ),
        ),
      ),
    );
  }

  _getData() async {
    var loadData = await loadAsset();
    // uint8listBytes = loadData.buffer.asUint8List();
    uint8listBytes = header.appendBitmap(
        Uint8List.view(loadData.buffer));
    print('bytes ===> ${uint8listBytes.toString()}');
    setState(() {

    });
  }

  Future<ByteData> loadAsset() async {
    return await rootBundle.load('assets/algos/iTrend.algo');
  }

  _readFileByte() async {

    FilePickerResult filePickerResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['algo'],
    );

    if(filePickerResult != null) {
      File algoFile = File(filePickerResult.files.single.path);
      Uint8List bytes;
      await algoFile.readAsBytes().then((value) {
        bytes = Uint8List.fromList(value);
        uint8listBytes = header.appendBitmap(bytes);
        print('bytes ===> ${uint8listBytes.toString()}');
        setState(() {

        });

      }).catchError((onError) {
        print('Exception Error while reading file from path:' + onError.toString());
      });
    } else {
      print('file pick failed.');
    }
  }

}

class BMP332Header {
  int _width; // NOTE: width must be multiple of 4 as no account is made for bitmap padding
  int _height;

  Uint8List _bmp;
  int _totalHeaderSize;

  BMP332Header(this._width, this._height) : assert(_width & 3 == 0) {
    int baseHeaderSize = 54;
    _totalHeaderSize = baseHeaderSize + 1024; // base + color map
    int fileLength = _totalHeaderSize + _width * _height; // header + bitmap
    _bmp = new Uint8List(fileLength);
    ByteData bd = _bmp.buffer.asByteData();
    bd.setUint8(0, 0x42);
    bd.setUint8(1, 0x4d);
    bd.setUint32(2, fileLength, Endian.little); // file length
    bd.setUint32(10, _totalHeaderSize, Endian.little); // start of the bitmap
    bd.setUint32(14, 40, Endian.little); // info header size
    bd.setUint32(18, _width, Endian.little);
    bd.setUint32(22, _height, Endian.little);
    bd.setUint16(26, 1, Endian.little); // planes
    bd.setUint32(28, 8, Endian.little); // bpp
    bd.setUint32(30, 0, Endian.little); // compression
    bd.setUint32(34, _width * _height, Endian.little); // bitmap size
    // leave everything else as zero

    // there are 256 possible variations of pixel
    // build the indexed color map that maps from packed byte to RGBA32
    // better still, create a lookup table see: http://unwind.se/bgr233/
    for (int rgb = 0; rgb < 256; rgb++) {
      int offset = baseHeaderSize + rgb * 4;

      int red = rgb & 0xe0;
      int green = rgb << 3 & 0xe0;
      int blue = rgb & 6 & 0xc0;

      bd.setUint8(offset + 3, 255); // A
      bd.setUint8(offset + 2, red); // R
      bd.setUint8(offset + 1, green); // G
      bd.setUint8(offset, blue); // B
    }
  }

  /// Insert the provided bitmap after the header and return the whole BMP
  Uint8List appendBitmap(Uint8List bitmap) {
    int size = _width * _height;
    assert(bitmap.length == size);
    _bmp.setRange(_totalHeaderSize, _totalHeaderSize + size, bitmap);
    return _bmp;
  }

}