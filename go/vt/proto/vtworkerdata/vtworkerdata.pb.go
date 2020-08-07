// Code generated by protoc-gen-go. DO NOT EDIT.
// source: vtworkerdata.proto

package vtworkerdata

import (
	fmt "fmt"
	math "math"

	proto "github.com/golang/protobuf/proto"
	logutil "github.com/liquidata-inc/vitess/go/vt/proto/logutil"
)

// Reference imports to suppress errors if they are not otherwise used.
var _ = proto.Marshal
var _ = fmt.Errorf
var _ = math.Inf

// This is a compile-time assertion to ensure that this generated file
// is compatible with the proto package it is being compiled against.
// A compilation error at this line likely means your copy of the
// proto package needs to be updated.
const _ = proto.ProtoPackageIsVersion3 // please upgrade the proto package

// ExecuteVtworkerCommandRequest is the payload for ExecuteVtworkerCommand.
type ExecuteVtworkerCommandRequest struct {
	Args                 []string `protobuf:"bytes,1,rep,name=args,proto3" json:"args,omitempty"`
	XXX_NoUnkeyedLiteral struct{} `json:"-"`
	XXX_unrecognized     []byte   `json:"-"`
	XXX_sizecache        int32    `json:"-"`
}

func (m *ExecuteVtworkerCommandRequest) Reset()         { *m = ExecuteVtworkerCommandRequest{} }
func (m *ExecuteVtworkerCommandRequest) String() string { return proto.CompactTextString(m) }
func (*ExecuteVtworkerCommandRequest) ProtoMessage()    {}
func (*ExecuteVtworkerCommandRequest) Descriptor() ([]byte, []int) {
	return fileDescriptor_32a791ab99179e8e, []int{0}
}

func (m *ExecuteVtworkerCommandRequest) XXX_Unmarshal(b []byte) error {
	return xxx_messageInfo_ExecuteVtworkerCommandRequest.Unmarshal(m, b)
}
func (m *ExecuteVtworkerCommandRequest) XXX_Marshal(b []byte, deterministic bool) ([]byte, error) {
	return xxx_messageInfo_ExecuteVtworkerCommandRequest.Marshal(b, m, deterministic)
}
func (m *ExecuteVtworkerCommandRequest) XXX_Merge(src proto.Message) {
	xxx_messageInfo_ExecuteVtworkerCommandRequest.Merge(m, src)
}
func (m *ExecuteVtworkerCommandRequest) XXX_Size() int {
	return xxx_messageInfo_ExecuteVtworkerCommandRequest.Size(m)
}
func (m *ExecuteVtworkerCommandRequest) XXX_DiscardUnknown() {
	xxx_messageInfo_ExecuteVtworkerCommandRequest.DiscardUnknown(m)
}

var xxx_messageInfo_ExecuteVtworkerCommandRequest proto.InternalMessageInfo

func (m *ExecuteVtworkerCommandRequest) GetArgs() []string {
	if m != nil {
		return m.Args
	}
	return nil
}

// ExecuteVtworkerCommandResponse is streamed back by ExecuteVtworkerCommand.
type ExecuteVtworkerCommandResponse struct {
	Event                *logutil.Event `protobuf:"bytes,1,opt,name=event,proto3" json:"event,omitempty"`
	XXX_NoUnkeyedLiteral struct{}       `json:"-"`
	XXX_unrecognized     []byte         `json:"-"`
	XXX_sizecache        int32          `json:"-"`
}

func (m *ExecuteVtworkerCommandResponse) Reset()         { *m = ExecuteVtworkerCommandResponse{} }
func (m *ExecuteVtworkerCommandResponse) String() string { return proto.CompactTextString(m) }
func (*ExecuteVtworkerCommandResponse) ProtoMessage()    {}
func (*ExecuteVtworkerCommandResponse) Descriptor() ([]byte, []int) {
	return fileDescriptor_32a791ab99179e8e, []int{1}
}

func (m *ExecuteVtworkerCommandResponse) XXX_Unmarshal(b []byte) error {
	return xxx_messageInfo_ExecuteVtworkerCommandResponse.Unmarshal(m, b)
}
func (m *ExecuteVtworkerCommandResponse) XXX_Marshal(b []byte, deterministic bool) ([]byte, error) {
	return xxx_messageInfo_ExecuteVtworkerCommandResponse.Marshal(b, m, deterministic)
}
func (m *ExecuteVtworkerCommandResponse) XXX_Merge(src proto.Message) {
	xxx_messageInfo_ExecuteVtworkerCommandResponse.Merge(m, src)
}
func (m *ExecuteVtworkerCommandResponse) XXX_Size() int {
	return xxx_messageInfo_ExecuteVtworkerCommandResponse.Size(m)
}
func (m *ExecuteVtworkerCommandResponse) XXX_DiscardUnknown() {
	xxx_messageInfo_ExecuteVtworkerCommandResponse.DiscardUnknown(m)
}

var xxx_messageInfo_ExecuteVtworkerCommandResponse proto.InternalMessageInfo

func (m *ExecuteVtworkerCommandResponse) GetEvent() *logutil.Event {
	if m != nil {
		return m.Event
	}
	return nil
}

func init() {
	proto.RegisterType((*ExecuteVtworkerCommandRequest)(nil), "vtworkerdata.ExecuteVtworkerCommandRequest")
	proto.RegisterType((*ExecuteVtworkerCommandResponse)(nil), "vtworkerdata.ExecuteVtworkerCommandResponse")
}

func init() { proto.RegisterFile("vtworkerdata.proto", fileDescriptor_32a791ab99179e8e) }

var fileDescriptor_32a791ab99179e8e = []byte{
	// 175 bytes of a gzipped FileDescriptorProto
	0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0xff, 0xe2, 0x12, 0x2a, 0x2b, 0x29, 0xcf,
	0x2f, 0xca, 0x4e, 0x2d, 0x4a, 0x49, 0x2c, 0x49, 0xd4, 0x2b, 0x28, 0xca, 0x2f, 0xc9, 0x17, 0xe2,
	0x41, 0x16, 0x93, 0xe2, 0xcd, 0xc9, 0x4f, 0x2f, 0x2d, 0xc9, 0xcc, 0x81, 0x48, 0x2a, 0x19, 0x73,
	0xc9, 0xba, 0x56, 0xa4, 0x26, 0x97, 0x96, 0xa4, 0x86, 0x41, 0x55, 0x39, 0xe7, 0xe7, 0xe6, 0x26,
	0xe6, 0xa5, 0x04, 0xa5, 0x16, 0x96, 0xa6, 0x16, 0x97, 0x08, 0x09, 0x71, 0xb1, 0x24, 0x16, 0xa5,
	0x17, 0x4b, 0x30, 0x2a, 0x30, 0x6b, 0x70, 0x06, 0x81, 0xd9, 0x4a, 0x6e, 0x5c, 0x72, 0xb8, 0x34,
	0x15, 0x17, 0xe4, 0xe7, 0x15, 0xa7, 0x0a, 0xa9, 0x70, 0xb1, 0xa6, 0x96, 0xa5, 0xe6, 0x95, 0x48,
	0x30, 0x2a, 0x30, 0x6a, 0x70, 0x1b, 0xf1, 0xe9, 0xc1, 0x6c, 0x75, 0x05, 0x89, 0x06, 0x41, 0x24,
	0x9d, 0xb4, 0xa3, 0x34, 0xcb, 0x32, 0x4b, 0x52, 0x8b, 0x8b, 0xf5, 0x32, 0xf3, 0xf5, 0x21, 0x2c,
	0xfd, 0xf4, 0x7c, 0xfd, 0xb2, 0x12, 0x7d, 0xb0, 0xe3, 0xf4, 0x91, 0x1d, 0x9e, 0xc4, 0x06, 0x16,
	0x33, 0x06, 0x04, 0x00, 0x00, 0xff, 0xff, 0xcf, 0x82, 0xc8, 0x11, 0xe3, 0x00, 0x00, 0x00,
}
