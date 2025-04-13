public class QueueSet : GenericSet<string?> {
	public QueueSet () {
		base (str_hash, str_equal);
	}
}
