part of 'message_model.dart';



class MessageModelAdapter extends TypeAdapter<MessageModel> {
  @override
  final int typeId = 0;
  @override
  MessageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageModel(
      id: fields[0] as String,
      conversationId: fields[1] as String,
      senderId: fields[2] as String,
      text: fields[3] as String?,
      imageFileIds: (fields[7] as List?)?.cast<String>(),
      imageUrls: (fields[8] as List?)?.cast<String>(),
      localImagePaths: (fields[9] as List?)?.cast<String>(),
      type: fields[4] as MessageType,
      timestamp: fields[5] as DateTime,
      status: fields[6] as MessageStatus,
    );
  }
  @override
  void write(BinaryWriter writer, MessageModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.conversationId)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.text)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.imageFileIds)
      ..writeByte(8)
      ..write(obj.imageUrls)
      ..writeByte(9)
      ..write(obj.localImagePaths);
  }
  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
