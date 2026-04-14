import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;

/// Little-endian float32 serialization used in `item_embeddings.vector`.
///
/// Vectors are normalized to unit length before encoding (see
/// docs/plans/vector-normalization.md for rationale). This means
/// stored vectors are always unit vectors, and cosine similarity
/// between any two stored vectors (or a stored vector and a
/// query vector that has also been normalized) reduces to a simple
/// dot product — eliminating the sqrt and division overhead of
/// full cosine similarity.
class EmbeddingCodec {
  EmbeddingCodec._();

  /// Normalize a vector in-place to unit length (L2 norm = 1).
  /// Returns the same list for chaining. If the input has zero norm
  /// (all zeros — shouldn't happen from a healthy embedding API),
  /// returns the input unchanged rather than dividing by zero.
  static List<double> normalize(List<double> vector) {
    double normSquared = 0.0;
    for (int i = 0; i < vector.length; i++) {
      normSquared += vector[i] * vector[i];
    }
    if (normSquared == 0.0) return vector;
    final invNorm = 1.0 / math.sqrt(normSquared);
    for (int i = 0; i < vector.length; i++) {
      vector[i] *= invNorm;
    }
    return vector;
  }

  /// Encode a vector as a little-endian float32 blob (4 bytes per
  /// dimension). The vector is normalized to unit length before
  /// encoding — see docs/plans/vector-normalization.md for the
  /// rationale.
  ///
  /// Note: this mutates the caller's list (in-place normalization).
  /// Callers that need the original vector should pass a copy.
  static Uint8List encode(List<double> vector) {
    normalize(vector);
    final bytes = Uint8List(vector.length * 4);
    final view = ByteData.view(bytes.buffer);
    for (int i = 0; i < vector.length; i++) {
      view.setFloat32(i * 4, vector[i], Endian.little);
    }
    return bytes;
  }

  /// Decode a little-endian float32 blob back into a `List<double>`.
  static List<double> decode(Uint8List bytes) {
    final view =
        ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes);
    final count = bytes.length ~/ 4;
    final out = Float64List(count);
    for (int i = 0; i < count; i++) {
      out[i] = view.getFloat32(i * 4, Endian.little).toDouble();
    }
    return out;
  }

  /// Dot product of two equal-length vectors. When both inputs are
  /// unit vectors (the standard case after normalization at write
  /// time), this is exactly the cosine similarity.
  static double dot(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }

  /// Full cosine similarity (handles non-unit vectors). Retained for
  /// debugging and testing — production code uses [dot] on pre-
  /// normalized vectors instead.
  @visibleForTesting
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    double dotProd = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dotProd += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProd / (math.sqrt(normA) * math.sqrt(normB));
  }
}
